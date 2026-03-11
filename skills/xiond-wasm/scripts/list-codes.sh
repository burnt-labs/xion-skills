#!/bin/bash
set -euo pipefail

# List all uploaded WASM codes on the chain
# Usage: list-codes.sh [options]
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
Usage: list-codes.sh [options]

List all uploaded WASM code IDs on the XION blockchain.

Options:
  --network <network>    Network to use: testnet or mainnet
                         (default: testnet, or XION_NETWORK env var)
  --node-url <url>       RPC node URL (overrides network setting)
  --help                 Show this help message

Environment:
  XION_NETWORK           Default network (testnet or mainnet)

Examples:
  list-codes.sh
  list-codes.sh --network mainnet
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
            PAYLOAD_JSON='{"success":false,"error":"Unknown option. Use --help for usage."}' emit_json
            exit 1
            ;;
    esac
done

if ! DEFAULT_NODE_URL=$(NETWORK_CONFIG "$NETWORK" 2>/dev/null); then
    PAYLOAD_JSON="$(NETWORK="$NETWORK" python3 - <<'PY'
import json, os
print(json.dumps({"success": False, "error": f"Invalid network '{os.environ['NETWORK']}'. Use: testnet or mainnet"}))
PY
)" emit_json
    exit 1
fi

NODE_URL="${NODE_URL:-$DEFAULT_NODE_URL}"

echo "Listing uploaded WASM codes on $NETWORK..." >&2

if ! RESULT=$(xiond query wasm list-code --node "$NODE_URL" --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Query failed: {err}"}))
PY
)" emit_json
    exit 1
fi

PAYLOAD_JSON="$(RAW="$RESULT" NETWORK="$NETWORK" python3 - <<'PY'
import json, os, sys

raw = os.environ.get("RAW", "")
network = os.environ["NETWORK"]

try:
    data = json.loads(raw)
except Exception:
    print(json.dumps({"success": False, "error": "xiond returned non-JSON output"}))
    sys.exit(0)

code_infos = data.get("code_infos", data.get("codes", []))
codes = []

for code in code_infos:
    codes.append({
        "code_id": code.get("code_id", ""),
        "creator": code.get("creator", ""),
        "data_hash": code.get("data_hash", code.get("checksum", "")),
        "instantiate_permission": code.get("instantiate_permission", {})
    })

print(json.dumps({
    "success": True,
    "network": network,
    "count": len(codes),
    "codes": codes
}))
PY
)" emit_json
