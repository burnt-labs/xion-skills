#!/bin/bash
set -e

# Optimize a CosmWasm contract using Docker
# Usage: optimize-contract.sh <contract-dir>
# Outputs JSON to stdout, status messages to stderr

if [[ $# -lt 1 ]]; then
    echo "{\"success\": false, \"error\": \"contract-dir is required\"}"
    exit 1
fi

CONTRACT_DIR="$1"

if [[ ! -d "$CONTRACT_DIR" ]]; then
    echo "{\"success\": false, \"error\": \"Directory '$CONTRACT_DIR' does not exist\"}"
    exit 1
fi

# Check if Docker is running
if ! docker ps &> /dev/null; then
    echo "{\"success\": false, \"error\": \"Docker is not running or not accessible\"}"
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
    echo "{\"success\": false, \"error\": \"Contract optimization failed\"}"
    exit 1
fi

# Find the optimized WASM file
WASM_FILE=$(find "$ABS_DIR/artifacts" -name "*.wasm" -type f 2>/dev/null | head -n 1)

if [[ -z "$WASM_FILE" ]]; then
    echo "{\"success\": false, \"error\": \"Optimized WASM file not found in artifacts directory\"}"
    exit 1
fi

echo "{\"success\": true, \"wasm_file\": \"$WASM_FILE\", \"message\": \"Contract optimized successfully\"}"
