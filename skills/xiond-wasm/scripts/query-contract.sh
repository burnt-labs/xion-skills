#!/bin/bash
set -e

# Query contract state
# Usage: query-contract.sh <contract-address> <query-msg> [node-url]
# Outputs JSON to stdout, status messages to stderr

# Check if xiond is installed
if ! command -v xiond &> /dev/null; then
    echo "{\"success\": false, \"error\": \"xiond command not found. Please use the xiond-init skill to install xiond first.\"}"
    exit 1
fi

if [[ $# -lt 2 ]]; then
    echo "{\"success\": false, \"error\": \"Usage: query-contract.sh <contract-address> <query-msg> [node-url]\"}"
    exit 1
fi

CONTRACT="$1"
QUERY_MSG="$2"
NODE_URL="${3:-https://rpc.xion-testnet-2.burnt.com:443}"

# Validate JSON format
if ! echo "$QUERY_MSG" | python3 -m json.tool &> /dev/null && ! echo "$QUERY_MSG" | jq . &> /dev/null; then
    echo "{\"success\": false, \"error\": \"query-msg must be valid JSON\"}"
    exit 1
fi

echo "Querying contract $CONTRACT..." >&2

# Query the contract
RESULT=$(xiond query wasm contract-state smart "$CONTRACT" "$QUERY_MSG" \
    --output json \
    --node "$NODE_URL" 2>&1)

if [[ $? -ne 0 ]]; then
    echo "{\"success\": false, \"error\": \"Query failed: $RESULT\"}"
    exit 1
fi

# Parse the result
if command -v jq &> /dev/null; then
    QUERY_RESULT=$(echo "$RESULT" | jq -c '.data' 2>/dev/null || echo "$RESULT")
    echo "{\"success\": true, \"contract\": \"$CONTRACT\", \"result\": $QUERY_RESULT}"
else
    # Fallback: return raw result
    echo "{\"success\": true, \"contract\": \"$CONTRACT\", \"raw_result\": $RESULT}"
fi
