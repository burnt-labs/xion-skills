#!/bin/bash
set -euo pipefail

# Query contract state
# Usage: query-contract.sh [options] <contract-address> <query-msg>
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
Usage: query-contract.sh [options] <contract-address> <query-msg>

Query the state of an instantiated WASM contract.

Arguments:
  <contract-address>  Contract address to query
  <query-msg>         JSON query message

Options:
  --network <network>    Network to use: testnet or mainnet
                         (default: testnet, or XION_NETWORK env var)
  --node-url <url>       RPC node URL (overrides network setting)
  --help                 Show this help message

Environment:
  XION_NETWORK           Default network (testnet or mainnet)

Examples:
  query-contract.sh xion1... '{"get_count":{}}'
  query-contract.sh --network mainnet xion1... '{"get_count":{}}'
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

if [[ $# -lt 2 ]]; then
    PAYLOAD_JSON='{"success":false,"error":"Usage: query-contract.sh [options] <contract-address> <query-msg>. Use --help for details."}' emit_json
    exit 1
fi

CONTRACT="$1"
QUERY_MSG="$2"

if ! DEFAULT_NODE_URL=$(NETWORK_CONFIG "$NETWORK" 2>/dev/null); then
    PAYLOAD_JSON="$(NETWORK="$NETWORK" python3 - <<'PY'
import json, os
print(json.dumps({"success": False, "error": f"Invalid network '{os.environ['NETWORK']}'. Use: testnet or mainnet"}))
PY
)" emit_json
    exit 1
fi

NODE_URL="${NODE_URL:-$DEFAULT_NODE_URL}"

if ! echo "$QUERY_MSG" | python3 -m json.tool &> /dev/null; then
    PAYLOAD_JSON='{"success":false,"error":"query-msg must be valid JSON"}' emit_json
    exit 1
fi

echo "Querying contract $CONTRACT on $NETWORK..." >&2

if ! RESULT=$(xiond query wasm contract-state smart "$CONTRACT" "$QUERY_MSG" \
    --output json \
    --node "$NODE_URL" 2>&1); then
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
    print(json.dumps({"success": False, "error": "xiond returned non-JSON output", "contract": contract, "raw": raw}))
    sys.exit(0)

result = data.get("data", data)
print(json.dumps({"success": True, "network": network, "contract": contract, "result": result}))
PY
)" emit_json
