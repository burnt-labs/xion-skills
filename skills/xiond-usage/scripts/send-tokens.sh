#!/bin/bash
set -euo pipefail

# Send tokens between accounts using xiond
# Usage: send-tokens.sh <from> <to> <amount> [chain-id] [node-url]
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
    PAYLOAD_JSON='{"success":false,"error":"Usage: send-tokens.sh <from> <to> <amount> [chain-id] [node-url]"}' emit_json
    exit 1
fi

FROM="$1"
TO="$2"
AMOUNT="$3"
CHAIN_ID="${4:-xion-testnet-2}"
NODE_URL="${5:-https://rpc.xion-testnet-2.burnt.com:443}"

echo "Sending $AMOUNT from $FROM to $TO..." >&2

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

PAYLOAD_JSON="$(TXHASH="$TXHASH" FROM="$FROM" TO="$TO" AMOUNT="$AMOUNT" CHAIN_ID="$CHAIN_ID" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "txhash": os.environ["TXHASH"],
    "from": os.environ["FROM"],
    "to": os.environ["TO"],
    "amount": os.environ["AMOUNT"],
    "chain_id": os.environ["CHAIN_ID"],
}))
PY
)" emit_json
