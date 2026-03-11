#!/bin/bash
set -euo pipefail

# Instantiate an uploaded contract
# Usage: instantiate-contract.sh <code-id> <label> <init-msg> <wallet> [chain-id] [node-url]
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

if [[ $# -lt 4 ]]; then
    PAYLOAD_JSON='{"success":false,"error":"Usage: instantiate-contract.sh <code-id> <label> <init-msg> <wallet> [chain-id] [node-url]"}' emit_json
    exit 1
fi

CODE_ID="$1"
LABEL="$2"
INIT_MSG="$3"
WALLET="$4"
CHAIN_ID="${5:-xion-testnet-2}"
NODE_URL="${6:-https://rpc.xion-testnet-2.burnt.com:443}"

# Validate JSON format
if ! echo "$INIT_MSG" | python3 -m json.tool &> /dev/null; then
    PAYLOAD_JSON='{"success":false,"error":"init-msg must be valid JSON"}' emit_json
    exit 1
fi

echo "Instantiating contract with Code ID $CODE_ID..." >&2

# Instantiate the contract
if ! RESULT=$(xiond tx wasm instantiate "$CODE_ID" "$INIT_MSG" \
    --from "$WALLET" \
    --label "$LABEL" \
    --gas-prices 0.025uxion \
    --gas auto \
    --gas-adjustment 1.3 \
    -y \
    --no-admin \
    --chain-id "$CHAIN_ID" \
    --node "$NODE_URL" \
    --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Instantiation failed: {err}"}))
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
    PAYLOAD_JSON='{"success":false,"error":"Instantiation may have succeeded but failed to parse txhash"}' emit_json
    exit 1
fi

# Query the transaction to get contract address
echo "Retrieving contract address from transaction..." >&2
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

CONTRACT_ADDRESS="$(RAW="$TX_QUERY" python3 - <<'PY'
import json, os
raw = os.environ.get("RAW", "")
try:
    data = json.loads(raw)
except Exception:
    print("")
    raise SystemExit

events = data.get("events") or []
addr = ""
for ev in events:
    if ev.get("type") != "instantiate":
        continue
    for attr in ev.get("attributes") or []:
        if attr.get("key") == "_contract_address":
            addr = attr.get("value") or ""
            break
    if addr:
        break
print(addr)
PY
)"

if [[ -z "$CONTRACT_ADDRESS" ]]; then
    PAYLOAD_JSON="$(TXHASH="$TXHASH" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "txhash": os.environ["TXHASH"],
    "contract_address": None,
    "message": "Contract instantiated but address not found. Query transaction manually.",
}))
PY
)" emit_json
else
    PAYLOAD_JSON="$(TXHASH="$TXHASH" CONTRACT_ADDRESS="$CONTRACT_ADDRESS" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "txhash": os.environ["TXHASH"],
    "contract_address": os.environ["CONTRACT_ADDRESS"],
    "message": "Contract instantiated successfully",
}))
PY
)" emit_json
fi
