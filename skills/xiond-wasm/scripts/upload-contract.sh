#!/bin/bash
set -euo pipefail

# Upload a compiled WASM contract to the blockchain
# Usage: upload-contract.sh [options] <wasm-file> <wallet>
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
Usage: upload-contract.sh [options] <wasm-file> <wallet>

Upload a compiled WASM contract to the XION blockchain.

Arguments:
  <wasm-file>    Path to the compiled WASM file
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
  upload-contract.sh contract.wasm mywallet
  upload-contract.sh --network mainnet contract.wasm mywallet
  XION_NETWORK=mainnet upload-contract.sh contract.wasm mywallet
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

if [[ $# -lt 2 ]]; then
    PAYLOAD_JSON='{"success":false,"error":"Usage: upload-contract.sh [options] <wasm-file> <wallet>. Use --help for details."}' emit_json
    exit 1
fi

WASM_FILE="$1"
WALLET="$2"

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

if [[ ! -f "$WASM_FILE" ]]; then
    PAYLOAD_JSON="$(WASM_FILE="$WASM_FILE" python3 - <<'PY'
import json, os
wf = os.environ["WASM_FILE"]
print(json.dumps({"success": False, "error": f"WASM file '{wf}' does not exist"}))
PY
)" emit_json
    exit 1
fi

echo "Uploading contract $WASM_FILE to $NETWORK..." >&2

if ! RESULT=$(xiond tx wasm store "$WASM_FILE" \
    --chain-id "$CHAIN_ID" \
    --gas-adjustment 1.3 \
    --gas-prices 0.001uxion \
    --gas auto \
    -y \
    --output json \
    --node "$NODE_URL" \
    --from "$WALLET" 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Upload failed: {err}"}))
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
    PAYLOAD_JSON='{"success":false,"error":"Upload may have succeeded but failed to parse txhash"}' emit_json
    exit 1
fi

echo "Retrieving Code ID from transaction..." >&2
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

CODE_ID="$(RAW="$TX_QUERY" python3 - <<'PY'
import json, os
raw = os.environ.get("RAW", "")
try:
    data = json.loads(raw)
except Exception:
    print("")
    raise SystemExit

events = data.get("events") or []
code_id = ""
for ev in events:
    if ev.get("type") != "store_code":
        continue
    for attr in ev.get("attributes") or []:
        if attr.get("key") == "code_id":
            code_id = attr.get("value") or ""
            break
    if code_id:
        break

if not code_id:
    for ev in events:
        for attr in ev.get("attributes") or []:
            v = attr.get("value")
            if isinstance(v, str) and v.isdigit():
                code_id = v

print(code_id)
PY
)"

if [[ -z "$CODE_ID" ]]; then
    PAYLOAD_JSON="$(TXHASH="$TXHASH" NETWORK="$NETWORK" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "network": os.environ["NETWORK"],
    "txhash": os.environ["TXHASH"],
    "code_id": None,
    "message": "Contract uploaded but Code ID not found. Query transaction manually.",
}))
PY
)" emit_json
else
    PAYLOAD_JSON="$(TXHASH="$TXHASH" CODE_ID="$CODE_ID" NETWORK="$NETWORK" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "network": os.environ["NETWORK"],
    "txhash": os.environ["TXHASH"],
    "code_id": int(os.environ["CODE_ID"]),
    "message": "Contract uploaded successfully",
}))
PY
)" emit_json
fi
