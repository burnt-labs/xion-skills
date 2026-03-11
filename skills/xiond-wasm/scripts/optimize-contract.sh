#!/bin/bash
set -euo pipefail

# Optimize a CosmWasm contract using Docker
# Usage: optimize-contract.sh <contract-dir>
# Outputs JSON to stdout, status messages to stderr

emit_json() {
    python3 - <<'PY'
import json, os
payload = json.loads(os.environ["PAYLOAD_JSON"])
print(json.dumps(payload, ensure_ascii=False))
PY
}

if [[ $# -lt 1 ]]; then
    PAYLOAD_JSON='{"success":false,"error":"contract-dir is required"}' emit_json
    exit 1
fi

CONTRACT_DIR="$1"

if [[ ! -d "$CONTRACT_DIR" ]]; then
    PAYLOAD_JSON="$(CONTRACT_DIR="$CONTRACT_DIR" python3 - <<'PY'
import json, os
d = os.environ["CONTRACT_DIR"]
print(json.dumps({"success": False, "error": f"Directory '{d}' does not exist"}))
PY
)" emit_json
    exit 1
fi

# Check if Docker is running
if ! docker ps &> /dev/null; then
    PAYLOAD_JSON='{"success":false,"error":"Docker is not running or not accessible"}' emit_json
    exit 1
fi

echo "Optimizing contract in $CONTRACT_DIR..." >&2

# Get absolute path
ABS_DIR=$(cd "$CONTRACT_DIR" && pwd)
DIR_NAME=$(basename "$ABS_DIR")

# Run optimizer
if ! docker run --rm -v "$ABS_DIR":/code \
    --mount type=volume,source="${DIR_NAME}_cache",target=/target \
    --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
    cosmwasm/optimizer:0.16.1 2>&1; then
    PAYLOAD_JSON='{"success":false,"error":"Contract optimization failed"}' emit_json
    exit 1
fi

# Find the optimized WASM file
WASM_FILE=$(find "$ABS_DIR/artifacts" -name "*.wasm" -type f 2>/dev/null | head -n 1)

if [[ -z "$WASM_FILE" ]]; then
    PAYLOAD_JSON='{"success":false,"error":"Optimized WASM file not found in artifacts directory"}' emit_json
    exit 1
fi

PAYLOAD_JSON="$(WASM_FILE="$WASM_FILE" python3 - <<'PY'
import json, os
print(json.dumps({"success": True, "wasm_file": os.environ["WASM_FILE"], "message": "Contract optimized successfully"}))
PY
)" emit_json
