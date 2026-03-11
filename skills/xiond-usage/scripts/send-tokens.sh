#!/bin/bash
set -euo pipefail

# Send tokens between accounts using xiond
# Usage: send-tokens.sh <from> <to> <amount> [--network testnet|mainnet] [chain-id] [node-url]
# Outputs JSON to stdout, status messages to stderr

emit_json() {
    python3 - <<'PY'
import json, os
payload = json.loads(os.environ["PAYLOAD_JSON"])
print(json.dumps(payload, ensure_ascii=False))
PY
}

# Network configuration
get_network_config() {
    local network="$1"
    case "$network" in
        testnet|test)
            echo "xion-testnet-2 https://rpc.xion-testnet-2.burnt.com:443"
            ;;
        mainnet|main|prod)
            echo "xion-mainnet-1 https://rpc.xion-mainnet-1.burnt.com"
            ;;
        *)
            echo "" ""
            return 1
            ;;
    esac
}

# Check if xiond is installed
if ! command -v xiond &> /dev/null; then
    PAYLOAD_JSON='{"success":false,"error":"xiond command not found. Please use the xiond-init skill to install xiond first."}' emit_json
    exit 1
fi

# Parse arguments
FROM=""
TO=""
AMOUNT=""
NETWORK="${XION_NETWORK:-testnet}"
CHAIN_ID=""
NODE_URL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --network|-n)
            NETWORK="$2"
            shift 2
            ;;
        --network=*)
            NETWORK="${1#*=}"
            shift
            ;;
        --help|-h)
            PAYLOAD_JSON='{"success":false,"error":"Usage: send-tokens.sh <from> <to> <amount> [--network testnet|mainnet]","hint":"Or set XION_NETWORK environment variable"}' emit_json
            exit 1
            ;;
        *)
            if [[ -z "$FROM" ]]; then
                FROM="$1"
            elif [[ -z "$TO" ]]; then
                TO="$1"
            elif [[ -z "$AMOUNT" ]]; then
                AMOUNT="$1"
            elif [[ -z "$CHAIN_ID" ]]; then
                CHAIN_ID="$1"
            elif [[ -z "$NODE_URL" ]]; then
                NODE_URL="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$FROM" ]] || [[ -z "$TO" ]] || [[ -z "$AMOUNT" ]]; then
    PAYLOAD_JSON='{"success":false,"error":"Usage: send-tokens.sh <from> <to> <amount> [--network testnet|mainnet]"}' emit_json
    exit 1
fi

# Set network config if not explicitly provided
if [[ -z "$CHAIN_ID" ]] || [[ -z "$NODE_URL" ]]; then
    NET_CONFIG=$(get_network_config "$NETWORK")
    if [[ -z "$NET_CONFIG" ]]; then
        PAYLOAD_JSON="$(NETWORK="$NETWORK" python3 - <<'PY'
import json, os
print(json.dumps({"success": False, "error": f"Unknown network: {os.environ['NETWORK']}. Use 'testnet' or 'mainnet'."}))
PY
)" emit_json
        exit 1
    fi
    read -r DEFAULT_CHAIN_ID DEFAULT_NODE_URL <<< "$NET_CONFIG"
    CHAIN_ID="${CHAIN_ID:-$DEFAULT_CHAIN_ID}"
    NODE_URL="${NODE_URL:-$DEFAULT_NODE_URL}"
fi

echo "Sending $AMOUNT from $FROM to $TO on $NETWORK ($CHAIN_ID)..." >&2

# Execute the transaction
if ! RESULT=$(xiond tx bank send "$FROM" "$TO" "$AMOUNT" \
    --chain-id "$CHAIN_ID" \
    --node "$NODE_URL" \
    --from "$FROM" \
    --gas-prices 0.025uxion \
    --gas auto \
    --gas-adjustment 1.3 \
    -y \
    --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Transaction failed: {err}"}))
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
    PAYLOAD_JSON='{"success":false,"error":"Transaction may have succeeded but failed to parse txhash"}' emit_json
    exit 1
fi

PAYLOAD_JSON="$(TXHASH="$TXHASH" FROM="$FROM" TO="$TO" AMOUNT="$AMOUNT" CHAIN_ID="$CHAIN_ID" NETWORK="$NETWORK" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "txhash": os.environ["TXHASH"],
    "from": os.environ["FROM"],
    "to": os.environ["TO"],
    "amount": os.environ["AMOUNT"],
    "chain_id": os.environ["CHAIN_ID"],
    "network": os.environ["NETWORK"],
}))
PY
)" emit_json
