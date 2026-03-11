#!/bin/bash
set -euo pipefail

# Query contract state
# Usage: query-contract.sh <contract-address> <query-msg> [node-url]
# Outputs JSON to stdout, status messages to stderr

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

if [[ $# -lt 2 ]]; then
    PAYLOAD_JSON='{"success":false,"error":"Usage: query-contract.sh <contract-address> <query-msg> [node-url]"}' emit_json
    exit 1
fi

CONTRACT="$1"
QUERY_MSG="$2"
NODE_URL="${3:-https://rpc.xion-testnet-2.burnt.com:443}"

# Validate JSON format
if ! echo "$QUERY_MSG" | python3 -m json.tool &> /dev/null; then
    PAYLOAD_JSON='{"success":false,"error":"query-msg must be valid JSON"}' emit_json
    exit 1
fi

echo "Querying contract $CONTRACT..." >&2

# Query the contract
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

PAYLOAD_JSON="$(CONTRACT="$CONTRACT" RAW="$RESULT" python3 - <<'PY'
import json, os, sys
contract = os.environ["CONTRACT"]
raw = os.environ.get("RAW", "")

try:
    data = json.loads(raw)
except Exception:
    print(json.dumps({"success": False, "error": "xiond returned non-JSON output", "contract": contract, "raw": raw}))
    sys.exit(0)

result = data.get("data", data)
print(json.dumps({"success": True, "contract": contract, "result": result}))
PY
)" emit_json
