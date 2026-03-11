#!/bin/bash
set -euo pipefail

# Show xiond account information
# Usage: show-account.sh <keyname>
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

# Check if keyname exists
if ! xiond keys show "$KEYNAME" &> /dev/null; then
    PAYLOAD_JSON="$(KEYNAME="$KEYNAME" python3 - <<'PY'
import json, os
keyname = os.environ["KEYNAME"]
print(json.dumps({"success": False, "error": f"Key '{keyname}' not found"}))
PY
)" emit_json
    exit 1
fi

echo "Retrieving account information for '$KEYNAME'..." >&2

# Get address
ADDRESS=$(xiond keys show "$KEYNAME" -a 2>/dev/null || echo "")
if [[ -z "$ADDRESS" ]]; then
    PAYLOAD_JSON='{"success":false,"error":"Failed to retrieve address"}' emit_json
    exit 1
fi

# Get pubkey
PUBKEY=$(xiond keys show "$KEYNAME" -p 2>/dev/null || echo "")

PAYLOAD_JSON="$(KEYNAME="$KEYNAME" ADDRESS="$ADDRESS" PUBKEY="$PUBKEY" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "keyname": os.environ["KEYNAME"],
    "address": os.environ["ADDRESS"],
    "pubkey": os.environ.get("PUBKEY", ""),
}))
PY
)" emit_json
