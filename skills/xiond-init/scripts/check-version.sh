#!/bin/bash
set -euo pipefail

# Check xiond version and installation status
# Usage: check-version.sh
# Outputs JSON to stdout, status messages to stderr

emit_json() {
    python3 - <<'PY'
import json, os
payload = json.loads(os.environ["PAYLOAD_JSON"])
print(json.dumps(payload, ensure_ascii=False))
PY
}

echo "Checking xiond installation..." >&2

# Check if xiond is installed
if ! command -v xiond &> /dev/null; then
    PAYLOAD_JSON='{"success":true,"installed":false,"version":null,"path":null,"message":"xiond is not installed"}' emit_json
    exit 0
fi

# Get version
VERSION=$(xiond version 2>&1 || echo "")

# Get path
XIOND_PATH=$(which xiond 2>/dev/null || echo "")

if [[ -z "$VERSION" ]]; then
    PAYLOAD_JSON='{"success":false,"installed":true,"version":null,"path":null,"message":"xiond is installed but version check failed"}' emit_json
    exit 1
fi

PAYLOAD_JSON="$(VERSION="$VERSION" XIOND_PATH="$XIOND_PATH" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "installed": True,
    "version": os.environ.get("VERSION", ""),
    "path": os.environ.get("XIOND_PATH", ""),
    "message": "xiond is installed"
}))
PY
)" emit_json
