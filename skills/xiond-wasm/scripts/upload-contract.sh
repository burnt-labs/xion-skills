#!/bin/bash
set -euo pipefail

# Upload a compiled WASM contract to the blockchain
# Usage: upload-contract.sh <wasm-file> <wallet> [chain-id] [node-url]
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
    PAYLOAD_JSON='{"success":false,"error":"Usage: upload-contract.sh <wasm-file> <wallet> [chain-id] [node-url]"}' emit_json
    exit 1
fi

WASM_FILE="$1"
WALLET="$2"
CHAIN_ID="${3:-xion-testnet-2}"
NODE_URL="${4:-https://rpc.xion-testnet-2.burnt.com:443}"

if [[ ! -f "$WASM_FILE" ]]; then
    PAYLOAD_JSON="$(WASM_FILE="$WASM_FILE" python3 - <<'PY'
import json, os
wf = os.environ["WASM_FILE"]
print(json.dumps({"success": False, "error": f"WASM file '{wf}' does not exist"}))
PY
)" emit_json
    exit 1
fi

echo "Uploading contract $WASM_FILE..." >&2

# Upload the contract
if ! RESULT=$(xiond tx wasm store "$WASM_FILE" \
    --chain-id "$CHAIN_ID" \
    --gas-adjustment 1.3 \
    --gas-prices 0.001uxion \
    --gas auto \
    -y \
    --output json \
    --node "$NODE_URL" \
    --from "$WALLET" 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Upload failed: {err}"}))
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
    PAYLOAD_JSON='{"success":false,"error":"Upload may have succeeded but failed to parse txhash"}' emit_json
    exit 1
fi

# Query the transaction to get Code ID
echo "Retrieving Code ID from transaction..." >&2
if ! TX_QUERY=$(xiond query tx "$TXHASH" \
    --node "$NODE_URL" \
    --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$TX_QUERY" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Failed to query transaction: {err}"}))
PY
)" emit_json
    exit 1
fi

CODE_ID="$(RAW="$TX_QUERY" python3 - <<'PY'
import json, os
raw = os.environ.get("RAW", "")
try:
    data = json.loads(raw)
except Exception:
    print("")
    raise SystemExit

events = data.get("events") or []
code_id = ""
for ev in events:
    if ev.get("type") != "store_code":
        continue
    for attr in ev.get("attributes") or []:
        if attr.get("key") == "code_id":
            code_id = attr.get("value") or ""
            break
    if code_id:
        break

if not code_id:
    # Fallback: scan all attributes for something that looks numeric
    for ev in events:
        for attr in ev.get("attributes") or []:
            v = attr.get("value")
            if isinstance(v, str) and v.isdigit():
                code_id = v
    # leave empty if still not found

print(code_id)
PY
)"

if [[ -z "$CODE_ID" ]]; then
    PAYLOAD_JSON="$(TXHASH="$TXHASH" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "txhash": os.environ["TXHASH"],
    "code_id": None,
    "message": "Contract uploaded but Code ID not found. Query transaction manually.",
}))
PY
)" emit_json
else
    PAYLOAD_JSON="$(TXHASH="$TXHASH" CODE_ID="$CODE_ID" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "txhash": os.environ["TXHASH"],
    "code_id": int(os.environ["CODE_ID"]),
    "message": "Contract uploaded successfully",
}))
PY
)" emit_json
fi
