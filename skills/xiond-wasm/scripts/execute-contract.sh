#!/bin/bash
set -euo pipefail

# Execute a contract message
# Usage: execute-contract.sh [options] <contract-address> <execute-msg> <wallet>
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
Usage: execute-contract.sh [options] <contract-address> <execute-msg> <wallet>

Execute a message on an instantiated WASM contract.

Arguments:
  <contract-address>  Contract address to execute
  <execute-msg>       JSON execute message
  <wallet>            Wallet name or address to sign the transaction

Options:
  --network <network>    Network to use: testnet or mainnet
                         (default: testnet, or XION_NETWORK env var)
  --chain-id <id>        Chain ID (overrides network setting)
  --node-url <url>       RPC node URL (overrides network setting)
  --help                 Show this help message

Environment:
  XION_NETWORK           Default network (testnet or mainnet)

Examples:
  execute-contract.sh xion1... '{"increment":{}}' mywallet
  execute-contract.sh --network mainnet xion1... '{"increment":{}}' mywallet
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

if [[ $# -lt 3 ]]; then
    PAYLOAD_JSON='{"success":false,"error":"Usage: execute-contract.sh [options] <contract-address> <execute-msg> <wallet>. Use --help for details."}' emit_json
    exit 1
fi

CONTRACT="$1"
EXECUTE_MSG="$2"
WALLET="$3"

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

if ! echo "$EXECUTE_MSG" | python3 -m json.tool &> /dev/null; then
    PAYLOAD_JSON='{"success":false,"error":"execute-msg must be valid JSON"}' emit_json
    exit 1
fi

echo "Executing contract $CONTRACT on $NETWORK..." >&2

if ! RESULT=$(xiond tx wasm execute "$CONTRACT" "$EXECUTE_MSG" \
    --from "$WALLET" \
    --gas-prices 0.025uxion \
    --gas auto \
    --gas-adjustment 1.3 \
    -y \
    --node "$NODE_URL" \
    --chain-id "$CHAIN_ID" \
    --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Execution failed: {err}"}))
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
    PAYLOAD_JSON='{"success":false,"error":"Execution may have succeeded but failed to parse txhash"}' emit_json
    exit 1
fi

PAYLOAD_JSON="$(TXHASH="$TXHASH" CONTRACT="$CONTRACT" NETWORK="$NETWORK" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "network": os.environ["NETWORK"],
    "txhash": os.environ["TXHASH"],
    "contract": os.environ["CONTRACT"],
    "message": "Transaction executed successfully",
}))
PY
)" emit_json
