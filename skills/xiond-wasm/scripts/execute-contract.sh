#!/bin/bash
set -e

# Execute a contract message
# Usage: execute-contract.sh <contract-address> <execute-msg> <wallet> [chain-id] [node-url]
# Outputs JSON to stdout, status messages to stderr

# Check if xiond is installed
if ! command -v xiond &> /dev/null; then
    echo "{\"success\": false, \"error\": \"xiond command not found. Please use the xiond-init skill to install xiond first.\"}"
    exit 1
fi

if [[ $# -lt 3 ]]; then
    echo "{\"success\": false, \"error\": \"Usage: execute-contract.sh <contract-address> <execute-msg> <wallet> [chain-id] [node-url]\"}"
    exit 1
fi

CONTRACT="$1"
EXECUTE_MSG="$2"
WALLET="$3"
CHAIN_ID="${4:-xion-testnet-2}"
NODE_URL="${5:-https://rpc.xion-testnet-2.burnt.com:443}"

# Validate JSON format
if ! echo "$EXECUTE_MSG" | python3 -m json.tool &> /dev/null && ! echo "$EXECUTE_MSG" | jq . &> /dev/null; then
    echo "{\"success\": false, \"error\": \"execute-msg must be valid JSON\"}"
    exit 1
fi

echo "Executing contract $CONTRACT..." >&2

# Execute the contract
RESULT=$(xiond tx wasm execute "$CONTRACT" "$EXECUTE_MSG" \
    --from "$WALLET" \
    --gas-prices 0.025uxion \
    --gas auto \
    --gas-adjustment 1.3 \
    -y \
    --node "$NODE_URL" \
    --chain-id "$CHAIN_ID" \
    --output json 2>&1)

if [[ $? -ne 0 ]]; then
    echo "{\"success\": false, \"error\": \"Execution failed: $RESULT\"}"
    exit 1
fi

# Extract txhash
TXHASH=$(echo "$RESULT" | grep -o '"txhash":"[^"]*"' | cut -d'"' -f4 || echo "")

if [[ -z "$TXHASH" ]]; then
    TXHASH=$(echo "$RESULT" | grep "txhash:" | awk '{print $2}' | tr -d '"' || echo "")
fi

if [[ -z "$TXHASH" ]]; then
    echo "{\"success\": false, \"error\": \"Execution may have succeeded but failed to parse txhash\"}"
    exit 1
fi

echo "{\"success\": true, \"txhash\": \"$TXHASH\", \"contract\": \"$CONTRACT\", \"message\": \"Transaction executed successfully\"}"
