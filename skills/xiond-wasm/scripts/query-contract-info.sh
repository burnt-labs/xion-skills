#!/bin/bash
set -euo pipefail

# Query contract information by address
# Usage: query-contract-info.sh [options] <contract-address>
# Outputs JSON to stdout, status messages to stderr

NETWORK_CONFIG() {
    local network="$1"
    case "$network" in
        testnet)
            echo "https://rpc.xion-testnet-2.burnt.com:443"
            ;;
        mainnet)
            echo "https://rpc.xion-mainnet-1.burnt.com"
            ;;
        *)
            return 1
            ;;
    esac
}

show_help() {
    cat >&2 << 'EOF'
Usage: query-contract-info.sh [options] <contract-address>

Query information about a contract instance.

Arguments:
  <contract-address>  Contract address to query

Options:
  --network <network>    Network to use: testnet or mainnet
                         (default: testnet, or XION_NETWORK env var)
  --node-url <url>       RPC node URL (overrides network setting)
  --help                 Show this help message

Environment:
  XION_NETWORK           Default network (testnet or mainnet)

Examples:
  query-contract-info.sh xion1...
  query-contract-info.sh --network mainnet xion1...
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
NODE_URL=""

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --network)
            NETWORK="$2"
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

if [[ $# -lt 1 ]]; then
    PAYLOAD_JSON='{"success":false,"error":"contract-address is required. Use --help for details."}' emit_json
    exit 1
fi

CONTRACT="$1"

if ! DEFAULT_NODE_URL=$(NETWORK_CONFIG "$NETWORK" 2>/dev/null); then
    PAYLOAD_JSON="$(NETWORK="$NETWORK" python3 - <<'PY'
import json, os
print(json.dumps({"success": False, "error": f"Invalid network '{os.environ['NETWORK']}'. Use: testnet or mainnet"}))
PY
)" emit_json
    exit 1
fi

NODE_URL="${NODE_URL:-$DEFAULT_NODE_URL}"

echo "Querying contract info for $CONTRACT on $NETWORK..." >&2

if ! RESULT=$(xiond query wasm contract "$CONTRACT" --node "$NODE_URL" --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Query failed: {err}"}))
PY
)" emit_json
    exit 1
fi

PAYLOAD_JSON="$(CONTRACT="$CONTRACT" RAW="$RESULT" NETWORK="$NETWORK" python3 - <<'PY'
import json, os, sys

contract = os.environ["CONTRACT"]
raw = os.environ.get("RAW", "")
network = os.environ["NETWORK"]

try:
    data = json.loads(raw)
except Exception:
    print(json.dumps({"success": False, "error": "xiond returned non-JSON output", "contract": contract}))
    sys.exit(0)

result = {
    "success": True,
    "network": network,
    "contract_address": contract,
    "code_id": data.get("code_id", ""),
    "creator": data.get("creator", ""),
    "admin": data.get("admin", ""),
    "label": data.get("label", ""),
    "created": data.get("created", {}),
    "ibc_port_id": data.get("ibc_port_id", "")
}

print(json.dumps(result))
PY
)" emit_json
