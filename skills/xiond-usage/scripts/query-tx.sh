#!/bin/bash
set -euo pipefail

# Query transaction status by hash
# Usage: query-tx.sh [options] <txhash>
# Outputs JSON to stdout, status messages to stderr

get_node_url() {
    local network="$1"
    case "$network" in
        testnet) echo "https://rpc.xion-testnet-2.burnt.com:443" ;;
        mainnet) echo "https://rpc.xion-mainnet-1.burnt.com" ;;
        *)       echo "https://rpc.xion-testnet-2.burnt.com:443" ;;
    esac
}

show_help() {
    cat << 'EOF'
Usage: query-tx.sh [options] <txhash>

Query transaction status by hash.

Options:
  --network <network>  Network to query: testnet or mainnet
                       (default: testnet, or XION_NETWORK env var)
  --node-url <url>     Custom node URL (overrides --network)
  -h, --help           Show this help message

Network endpoints:
  testnet: https://rpc.xion-testnet-2.burnt.com:443
  mainnet: https://rpc.xion-mainnet-1.burnt.com

Examples:
  query-tx.sh ABC123...
  query-tx.sh --network mainnet ABC123...
  query-tx.sh --node-url https://custom-rpc.com ABC123...
  XION_NETWORK=mainnet query-tx.sh ABC123...
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
TXHASH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --network)
            if [[ -z "${2:-}" ]]; then
                PAYLOAD_JSON='{"success":false,"error":"--network requires a value (testnet|mainnet)"}' emit_json
                exit 1
            fi
            NETWORK="$2"
            shift 2
            ;;
        --node-url)
            if [[ -z "${2:-}" ]]; then
                PAYLOAD_JSON='{"success":false,"error":"--node-url requires a URL value"}' emit_json
                exit 1
            fi
            NODE_URL="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            PAYLOAD_JSON="{\"success\":false,\"error\":\"Unknown option: $1\"}" emit_json
            exit 1
            ;;
        *)
            if [[ -z "$TXHASH" ]]; then
                TXHASH="$1"
            else
                PAYLOAD_JSON='{"success":false,"error":"Multiple txhash arguments provided"}' emit_json
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$TXHASH" ]]; then
    PAYLOAD_JSON='{"success":false,"error":"txhash is required"}' emit_json
    exit 1
fi

if [[ -z "$NODE_URL" ]]; then
    NODE_URL=$(get_node_url "$NETWORK")
fi

echo "Querying transaction $TXHASH on $NETWORK..." >&2

if ! RESULT=$(xiond query tx "$TXHASH" --node "$NODE_URL" --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Transaction query failed: {err}"}))
PY
)" emit_json
    exit 1
fi

PAYLOAD_JSON="$(TXHASH="$TXHASH" NETWORK="$NETWORK" RAW="$RESULT" python3 - <<'PY'
import json, os, sys

txhash = os.environ["TXHASH"]
network = os.environ.get("NETWORK", "testnet")
raw = os.environ.get("RAW", "")

try:
    data = json.loads(raw)
except Exception:
    print(json.dumps({"success": False, "error": "xiond returned non-JSON output", "txhash": txhash, "network": network}))
    sys.exit(0)

code = data.get("code", -1)
height = data.get("height", "")
gas_used = data.get("gas_used", "")
gas_wanted = data.get("gas_wanted", "")
timestamp = data.get("timestamp", "")

events = data.get("events", [])
logs = data.get("logs", [])

status = "success" if code == 0 else "failed"

print(json.dumps({
    "success": True,
    "txhash": txhash,
    "network": network,
    "status": status,
    "code": code,
    "height": height,
    "gas_used": gas_used,
    "gas_wanted": gas_wanted,
    "timestamp": timestamp,
    "raw_events": events,
    "logs": logs
}))
PY
)" emit_json
