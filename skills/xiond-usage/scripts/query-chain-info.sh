#!/bin/bash
set -euo pipefail

# Query chain status and information
# Usage: query-chain-info.sh [options] [node-url]
# Outputs JSON to stdout, status messages to stderr

NETWORK_URLS() {
    case "$1" in
        testnet) echo "https://rpc.xion-testnet-2.burnt.com:443" ;;
        mainnet) echo "https://rpc.xion-mainnet-1.burnt.com" ;;
        *)       echo "" ;;
    esac
}

show_help() {
    cat <<'EOF'
Usage: query-chain-info.sh [options] [node-url]

Query XION chain status and information.

Options:
  --network <network>  Network to query: testnet or mainnet
                       (default: testnet or XION_NETWORK env var)
  --help               Show this help message

Arguments:
  node-url             Direct RPC endpoint URL (overrides --network)

Environment:
  XION_NETWORK         Default network if --network not specified

Examples:
  query-chain-info.sh
  query-chain-info.sh --network mainnet
  query-chain-info.sh https://rpc.xion-testnet-2.burnt.com:443
  XION_NETWORK=mainnet query-chain-info.sh
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
    case $1 in
        --network)
            NETWORK="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            PAYLOAD_JSON="{\"success\":false,\"error\":\"Unknown option: $1. Use --help for usage.\"}" emit_json
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
    NODE_URL="${POSITIONAL_ARGS[0]}"
fi

if [[ -z "$NODE_URL" ]]; then
    NODE_URL=$(NETWORK_URLS "$NETWORK")
    if [[ -z "$NODE_URL" ]]; then
        PAYLOAD_JSON="{\"success\":false,\"error\":\"Invalid network: $NETWORK. Use testnet or mainnet.\"}" emit_json
        exit 1
    fi
fi

echo "Querying chain status from $NODE_URL (network: $NETWORK)..." >&2

if ! RESULT=$(xiond status --node "$NODE_URL" 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Status query failed: {err}"}))
PY
)" emit_json
    exit 1
fi

PAYLOAD_JSON="$(RAW="$RESULT" NODE_URL="$NODE_URL" NETWORK="$NETWORK" python3 - <<'PY'
import json, os, sys

raw = os.environ.get("RAW", "")
node_url = os.environ.get("NODE_URL", "")
network = os.environ.get("NETWORK", "")

try:
    data = json.loads(raw)
except Exception:
    print(json.dumps({
        "success": True,
        "node_url": node_url,
        "network": network,
        "raw_output": raw,
        "message": "Status returned non-JSON output"
    }))
    sys.exit(0)

node_info = data.get("NodeInfo", data.get("node_info", {}))
sync_info = data.get("SyncInfo", data.get("sync_info", {}))
validator_info = data.get("ValidatorInfo", data.get("validator_info", {}))

result = {
    "success": True,
    "node_url": node_url,
    "network": network,
    "chain_id": node_info.get("network", node_info.get("default_node_info", {}).get("network", "")),
    "moniker": node_info.get("moniker", ""),
    "block_height": sync_info.get("latest_block_height", sync_info.get("latest_block_height", "")),
    "block_hash": sync_info.get("latest_block_hash", ""),
    "catching_up": sync_info.get("catching_up", False),
    "validator_address": validator_info.get("address", "")
}

print(json.dumps(result))
PY
)" emit_json
