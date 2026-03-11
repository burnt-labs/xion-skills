#!/bin/bash
set -euo pipefail

# Query account balance using xiond
# Usage: query-balance.sh <address> [--network testnet|mainnet|local] [node-url]
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
            echo "https://rpc.xion-testnet-2.burnt.com:443"
            ;;
        mainnet|main|prod)
            echo "https://rpc.xion-mainnet-1.burnt.com"
            ;;
        local|dev)
            echo "http://localhost:26657"
            ;;
        *)
            echo ""
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
ADDRESS=""
NETWORK="${XION_NETWORK:-testnet}"
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
            PAYLOAD_JSON='{"success":false,"error":"Usage: query-balance.sh <address> [--network testnet|mainnet|local]","hint":"Or set XION_NETWORK environment variable"}' emit_json
            exit 1
            ;;
        *)
            if [[ -z "$ADDRESS" ]]; then
                ADDRESS="$1"
            elif [[ -z "$NODE_URL" ]]; then
                NODE_URL="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$ADDRESS" ]]; then
    PAYLOAD_JSON='{"success":false,"error":"address is required"}' emit_json
    exit 1
fi

# Set node URL if not explicitly provided
if [[ -z "$NODE_URL" ]]; then
    NODE_URL=$(get_network_config "$NETWORK")
    if [[ -z "$NODE_URL" ]]; then
        PAYLOAD_JSON="$(NETWORK="$NETWORK" python3 - <<'PY'
import json, os
print(json.dumps({"success": False, "error": f"Unknown network: {os.environ['NETWORK']}. Use 'testnet', 'mainnet', or 'local'."}))
PY
)" emit_json
        exit 1
    fi
fi

echo "Querying balance for $ADDRESS on $NETWORK..." >&2

# Query the balance
if ! RESULT=$(xiond query bank balances "$ADDRESS" \
    --node "$NODE_URL" \
    --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Query failed: {err}"}))
PY
)" emit_json
    exit 1
fi

PAYLOAD_JSON="$(ADDRESS="$ADDRESS" RAW="$RESULT" NETWORK="$NETWORK" python3 - <<'PY'
import json, os, sys

address = os.environ["ADDRESS"]
raw = os.environ["RAW"]

try:
    data = json.loads(raw)
except Exception:
    print(json.dumps({"success": False, "error": "xiond returned non-JSON output", "address": address, "raw": raw}))
    sys.exit(0)

balances = data.get("balances", [])
print(json.dumps({"success": True, "address": address, "balances": balances, "network": os.environ.get("NETWORK", "testnet")}))
PY
)" emit_json
