#!/bin/bash
set -euo pipefail

# List all xiond keys/accounts in the keyring
# Usage: list-accounts.sh
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

echo "Listing all accounts in keyring..." >&2

# List keys in JSON format
if ! RESULT=$(xiond keys list --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$RESULT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Failed to list accounts: {err}"}))
PY
)" emit_json
    exit 1
fi

PAYLOAD_JSON="$(RAW="$RESULT" python3 - <<'PY'
import json, os

raw = os.environ.get("RAW", "[]")
try:
    keys = json.loads(raw)
except Exception:
    keys = []

accounts = []
for k in keys:
    accounts.append({
        "name": k.get("name", ""),
        "type": k.get("type", ""),
        "address": k.get("address", ""),
        "pubkey": k.get("pubkey", "")
    })

print(json.dumps({
    "success": True,
    "count": len(accounts),
    "accounts": accounts
}))
PY
)" emit_json
