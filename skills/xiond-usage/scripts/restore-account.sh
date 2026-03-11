#!/bin/bash
set -euo pipefail

# Restore an account from mnemonic phrase
# Usage: restore-account.sh <keyname>
# Reads mnemonic from stdin or prompts interactively
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

if [[ $# -lt 1 ]]; then
    PAYLOAD_JSON='{"success":false,"error":"keyname is required"}' emit_json
    exit 1
fi

KEYNAME="$1"

# Check if keyname already exists
if xiond keys show "$KEYNAME" &> /dev/null; then
    PAYLOAD_JSON="$(KEYNAME="$KEYNAME" python3 - <<'PY'
import json, os
keyname = os.environ["KEYNAME"]
print(json.dumps({"success": False, "error": f"Key '{keyname}' already exists. Use a different name or delete the existing key first."}))
PY
)" emit_json
    exit 1
fi

echo "Restoring account '$KEYNAME' from mnemonic..." >&2
echo "Enter your mnemonic phrase (24 words):" >&2

# Restore the key from mnemonic (interactive mode)
if ! OUTPUT=$(xiond keys add "$KEYNAME" --recover --output json 2>&1); then
    PAYLOAD_JSON="$(ERR_MSG="$OUTPUT" python3 - <<'PY'
import json, os
err = os.environ.get("ERR_MSG", "")
print(json.dumps({"success": False, "error": f"Failed to restore account: {err}"}))
PY
)" emit_json
    exit 1
fi

ADDRESS="$(RAW="$OUTPUT" python3 - <<'PY'
import json, os
raw = os.environ.get("RAW", "")
try:
    data = json.loads(raw)
except Exception:
    print("")
else:
    print(data.get("address", "") or "")
PY
)"

PUBKEY="$(RAW="$OUTPUT" python3 - <<'PY'
import json, os
raw = os.environ.get("RAW", "")
try:
    data = json.loads(raw)
except Exception:
    print("")
else:
    pub = data.get("pubkey")
    if isinstance(pub, dict):
        print(pub.get("key", "") or pub.get("@value", "") or "")
    else:
        print(pub or "")
PY
)"

if [[ -z "$ADDRESS" ]]; then
    # Fallback: query the keyring directly
    ADDRESS="$(xiond keys show "$KEYNAME" -a 2>/dev/null || echo "")"
    PUBKEY="$(xiond keys show "$KEYNAME" -p 2>/dev/null || echo "")"
fi

if [[ -z "$ADDRESS" ]]; then
    PAYLOAD_JSON='{"success":false,"error":"Account restored but failed to retrieve address"}' emit_json
    exit 1
fi

PAYLOAD_JSON="$(KEYNAME="$KEYNAME" ADDRESS="$ADDRESS" PUBKEY="$PUBKEY" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "keyname": os.environ["KEYNAME"],
    "address": os.environ["ADDRESS"],
    "pubkey": os.environ.get("PUBKEY", ""),
    "message": "Account restored successfully from mnemonic"
}))
PY
)" emit_json
