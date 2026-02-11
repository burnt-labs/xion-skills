#!/bin/bash
set -e

# Upload a compiled WASM contract to the blockchain
# Usage: upload-contract.sh <wasm-file> <wallet> [chain-id] [node-url]
# Outputs JSON to stdout, status messages to stderr

# Check if xiond is installed
if ! command -v xiond &> /dev/null; then
    echo "{\"success\": false, \"error\": \"xiond command not found. Please use the xiond-init skill to install xiond first.\"}"
    exit 1
fi

if [[ $# -lt 2 ]]; then
    echo "{\"success\": false, \"error\": \"Usage: upload-contract.sh <wasm-file> <wallet> [chain-id] [node-url]\"}"
    exit 1
fi

WASM_FILE="$1"
WALLET="$2"
CHAIN_ID="${3:-xion-testnet-2}"
NODE_URL="${4:-https://rpc.xion-testnet-2.burnt.com:443}"

if [[ ! -f "$WASM_FILE" ]]; then
    echo "{\"success\": false, \"error\": \"WASM file '$WASM_FILE' does not exist\"}"
    exit 1
fi

echo "Uploading contract $WASM_FILE..." >&2

# Upload the contract
RESULT=$(xiond tx wasm store "$WASM_FILE" \
    --chain-id "$CHAIN_ID" \
    --gas-adjustment 1.3 \
    --gas-prices 0.001uxion \
    --gas auto \
    -y \
    --output json \
    --node "$NODE_URL" \
    --from "$WALLET" 2>&1)

if [[ $? -ne 0 ]]; then
    echo "{\"success\": false, \"error\": \"Upload failed: $RESULT\"}"
    exit 1
fi

# Extract txhash
TXHASH=$(echo "$RESULT" | grep -o '"txhash":"[^"]*"' | cut -d'"' -f4 || echo "")

if [[ -z "$TXHASH" ]]; then
    TXHASH=$(echo "$RESULT" | grep "txhash:" | awk '{print $2}' | tr -d '"' || echo "")
fi

if [[ -z "$TXHASH" ]]; then
    echo "{\"success\": false, \"error\": \"Upload may have succeeded but failed to parse txhash\"}"
    exit 1
fi

# Query the transaction to get Code ID
echo "Retrieving Code ID from transaction..." >&2
TX_QUERY=$(xiond query tx "$TXHASH" \
    --node "$NODE_URL" \
    --output json 2>&1)

if [[ $? -ne 0 ]]; then
    echo "{\"success\": false, \"error\": \"Failed to query transaction: $TX_QUERY\"}"
    exit 1
fi

# Extract Code ID from events
CODE_ID=$(echo "$TX_QUERY" | grep -o '"value":"[0-9]*"' | grep -o '[0-9]*' | tail -n 1 || echo "")

# Try alternative method with jq if available
if [[ -z "$CODE_ID" ]] && command -v jq &> /dev/null; then
    CODE_ID=$(echo "$TX_QUERY" | jq -r '.events[-1].attributes[1].value' 2>/dev/null || echo "")
fi

# Try another method: look for code_id in events
if [[ -z "$CODE_ID" ]]; then
    CODE_ID=$(echo "$TX_QUERY" | grep -o '"code_id":"[0-9]*"' | grep -o '[0-9]*' || echo "")
fi

if [[ -z "$CODE_ID" ]]; then
    echo "{\"success\": true, \"txhash\": \"$TXHASH\", \"code_id\": null, \"message\": \"Contract uploaded but Code ID not found. Query transaction manually.\"}"
else
    echo "{\"success\": true, \"txhash\": \"$TXHASH\", \"code_id\": $CODE_ID, \"message\": \"Contract uploaded successfully\"}"
fi
