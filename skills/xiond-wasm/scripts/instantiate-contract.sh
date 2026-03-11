#!/bin/bash
set -euo pipefail

# Instantiate an uploaded contract
# Usage: instantiate-contract.sh [options] <code-id> <label> <init-msg> <wallet>
# Outputs JSON to stdout, status messages to stderr

NETWORK_CONFIG() {
    local network="$1"
    case "$network" in
        testnet)
            echo "xion-testnet-2 https://rpc.xion-testnet-2.burnt.com:443"
            ;;
        mainnet)
            echo "xion-mainnet-1 https://rpc.xion-mainnet-1.burnt.com"
            ;;
        *)
            return 1
            ;;
    esac
}

show_help() {
    cat >&2 << 'EOF'
Usage: instantiate-contract.sh [options] <code-id> <label> <init-msg> <wallet>

Instantiate an uploaded WASM contract on the XION blockchain.

Arguments:
  <code-id>      Code ID of the uploaded contract
  <label>        Human-readable label for the contract instance
  <init-msg>     JSON initialization message
  <wallet>       Wallet name or address to sign the transaction

Options:
  --network <network>    Network to use: testnet or mainnet
                         (default: testnet, or XION_NETWORK env var)
  --chain-id <id>        Chain ID (overrides network setting)
  --node-url <url>       RPC node URL (overrides network setting)
  --help                 Show this help message

Environment:
  XION_NETWORK           Default network (testnet or mainnet)

Examples:
  instantiate-contract.sh 1 "my-contract" '{"count":0}' mywallet
  instantiate-contract.sh --network mainnet 1 "my-contract" '{"count":0}' mywallet
EOF
}

emit_json() {
    python3 - <<'PY'
import json, os
payload = json.loads(os.environ["PAYLOAD_JSON"])
print(json.dumps(payload, ensure_ascii=False))
PY
}

if ! command -v xiond &> /dev/null; then
    PAYLOAD_JSON='{"success":false,"error":"xiond command not found. Please use the xiond-init skill to install xiond first."}' emit_json
    exit 1
fi

NETWORK="${XION_NETWORK:-testnet}"
CHAIN_ID=""
NODE_URL=""

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --network)
            NETWORK="$2"
            shift 2
            ;;
        --chain-id)
            CHAIN_ID="$2"
            shift 2
            ;;
        --node-url)
            NODE_URL="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

if [[ $# -lt 4 ]]; then
    PAYLOAD_JSON='{"success":false,"error":"Usage: instantiate-contract.sh [options] <code-id> <label> <init-msg> <wallet>. Use --help for details."}' emit_json
    exit 1
fi

CODE_ID="$1"
LABEL="$2"
INIT_MSG="$3"
WALLET="$4"

if ! CONFIG=$(NETWORK_CONFIG "$NETWORK" 2>/dev/null); then
    PAYLOAD_JSON="$(NETWORK="$NETWORK" python3 - <<'PY'
import json, os
print(json.dumps({"success": False, "error": f"Invalid network '{os.environ['NETWORK']}'. Use: testnet or mainnet"}))
PY
)" emit_json
    exit 1
fi

read -r DEFAULT_CHAIN_ID DEFAULT_NODE_URL <<< "$CONFIG"

CHAIN_ID="${CHAIN_ID:-$DEFAULT_CHAIN_ID}"
NODE_URL="${NODE_URL:-$DEFAULT_NODE_URL}"

if ! echo "$INIT_MSG" | python3 -m json.tool &> /dev/null; then
    PAYLOAD_JSON='{"success":false,"error":"init-msg must be valid JSON"}' emit_json
    exit 1
fi

echo "Instantiating contract with Code ID $CODE_ID on $NETWORK..." >&2

if ! RESULT=$(xiond tx wasm instantiate "$CODE_ID" "$INIT_MSG" \
    --from "$WALLET" \
    --label "$LABEL" \
    --gas-prices 0.025uxion \
    --gas auto \
    --gas-adjustment 1.3 \
    -y \
    --no-admin \
    --chain-id "$CHAIN_ID" \
    --node "$NODE_URL" \
    --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Instantiation failed: {err}"}))
PY
)" emit_json
    exit 1
fi

TXHASH="$(RAW="$RESULT" python3 - <<'PY'
import json, os
raw = os.environ.get("RAW", "")
try:
    data = json.loads(raw)
except Exception:
    print("")
else:
    print(data.get("txhash", "") or "")
PY
)"

if [[ -z "$TXHASH" ]]; then
    PAYLOAD_JSON='{"success":false,"error":"Instantiation may have succeeded but failed to parse txhash"}' emit_json
    exit 1
fi

echo "Retrieving contract address from transaction..." >&2
if ! TX_QUERY=$(xiond query tx "$TXHASH" \
    --node "$NODE_URL" \
    --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$TX_QUERY" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Failed to query transaction: {err}"}))
PY
)" emit_json
    exit 1
fi

CONTRACT_ADDRESS="$(RAW="$TX_QUERY" python3 - <<'PY'
import json, os
raw = os.environ.get("RAW", "")
try:
    data = json.loads(raw)
except Exception:
    print("")
    raise SystemExit

events = data.get("events") or []
addr = ""
for ev in events:
    if ev.get("type") != "instantiate":
        continue
    for attr in ev.get("attributes") or []:
        if attr.get("key") == "_contract_address":
            addr = attr.get("value") or ""
            break
    if addr:
        break
print(addr)
PY
)"

if [[ -z "$CONTRACT_ADDRESS" ]]; then
    PAYLOAD_JSON="$(TXHASH="$TXHASH" NETWORK="$NETWORK" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "network": os.environ["NETWORK"],
    "txhash": os.environ["TXHASH"],
    "contract_address": None,
    "message": "Contract instantiated but address not found. Query transaction manually.",
}))
PY
)" emit_json
else
    PAYLOAD_JSON="$(TXHASH="$TXHASH" CONTRACT_ADDRESS="$CONTRACT_ADDRESS" NETWORK="$NETWORK" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "network": os.environ["NETWORK"],
    "txhash": os.environ["TXHASH"],
    "contract_address": os.environ["CONTRACT_ADDRESS"],
    "message": "Contract instantiated successfully",
}))
PY
)" emit_json
fi
