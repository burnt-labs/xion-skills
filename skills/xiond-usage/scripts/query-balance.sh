#!/bin/bash
set -euo pipefail

# Query account balance using xiond
# Usage: query-balance.sh <address> [node-url]
# Outputs JSON to stdout, status messages to stderr

# Emit JSON safely via python (avoids broken quoting/newlines)
emit_json() {
    python3 - <<'PY'
import json, os
payload = json.loads(os.environ["PAYLOAD_JSON"])
print(json.dumps(payload, ensure_ascii=False))
PY
}

# Check if xiond is installed
if ! command -v xiond &> /dev/null; then
    PAYLOAD_JSON='{"success":false,"error":"xiond command not found. Please use the xiond-init skill to install xiond first."}' emit_json
    exit 1
fi

if [[ $# -lt 1 ]]; then
    PAYLOAD_JSON='{"success":false,"error":"address is required"}' emit_json
    exit 1
fi

ADDRESS="$1"
NODE_URL="${2:-https://rpc.xion-testnet-2.burnt.com:443}"

echo "Querying balance for $ADDRESS..." >&2

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

PAYLOAD_JSON="$(ADDRESS="$ADDRESS" RAW="$RESULT" python3 - <<'PY'
import json, os, sys

address = os.environ["ADDRESS"]
raw = os.environ["RAW"]

try:
    data = json.loads(raw)
except Exception:
    print(json.dumps({"success": False, "error": "xiond returned non-JSON output", "address": address, "raw": raw}))
    sys.exit(0)

balances = data.get("balances", [])
print(json.dumps({"success": True, "address": address, "balances": balances}))
PY
)" emit_json
