#!/bin/bash
set -euo pipefail

# Execute a contract message
# Usage: execute-contract.sh <contract-address> <execute-msg> <wallet> [chain-id] [node-url]
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

if [[ $# -lt 3 ]]; then
    PAYLOAD_JSON='{"success":false,"error":"Usage: execute-contract.sh <contract-address> <execute-msg> <wallet> [chain-id] [node-url]"}' emit_json
    exit 1
fi

CONTRACT="$1"
EXECUTE_MSG="$2"
WALLET="$3"
CHAIN_ID="${4:-xion-testnet-2}"
NODE_URL="${5:-https://rpc.xion-testnet-2.burnt.com:443}"

# Validate JSON format
if ! echo "$EXECUTE_MSG" | python3 -m json.tool &> /dev/null; then
    PAYLOAD_JSON='{"success":false,"error":"execute-msg must be valid JSON"}' emit_json
    exit 1
fi

echo "Executing contract $CONTRACT..." >&2

# Execute the contract
if ! RESULT=$(xiond tx wasm execute "$CONTRACT" "$EXECUTE_MSG" \
    --from "$WALLET" \
    --gas-prices 0.025uxion \
    --gas auto \
    --gas-adjustment 1.3 \
    -y \
    --node "$NODE_URL" \
    --chain-id "$CHAIN_ID" \
    --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Execution failed: {err}"}))
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
    PAYLOAD_JSON='{"success":false,"error":"Execution may have succeeded but failed to parse txhash"}' emit_json
    exit 1
fi

PAYLOAD_JSON="$(TXHASH="$TXHASH" CONTRACT="$CONTRACT" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "txhash": os.environ["TXHASH"],
    "contract": os.environ["CONTRACT"],
    "message": "Transaction executed successfully",
}))
PY
)" emit_json
