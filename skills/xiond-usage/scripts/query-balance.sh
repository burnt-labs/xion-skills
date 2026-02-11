#!/bin/bash
set -e

# Query account balance using xiond
# Usage: query-balance.sh <address> [node-url]
# Outputs JSON to stdout, status messages to stderr

# Check if xiond is installed
if ! command -v xiond &> /dev/null; then
    echo "{\"success\": false, \"error\": \"xiond command not found. Please use the xiond-init skill to install xiond first.\"}"
    exit 1
fi

if [[ $# -lt 1 ]]; then
    echo "{\"success\": false, \"error\": \"address is required\"}"
    exit 1
fi

ADDRESS="$1"
NODE_URL="${2:-https://rpc.xion-testnet-2.burnt.com:443}"

echo "Querying balance for $ADDRESS..." >&2

# Query the balance
RESULT=$(xiond query bank balances "$ADDRESS" \
    --node "$NODE_URL" \
    --output json 2>&1)

if [[ $? -ne 0 ]]; then
    echo "{\"success\": false, \"error\": \"Query failed: $RESULT\"}"
    exit 1
fi

# Parse balances from JSON output
BALANCES=$(echo "$RESULT" | grep -o '"balances":\[[^]]*\]' || echo "")

if [[ -z "$BALANCES" ]]; then
    # Try to extract balances array directly
    BALANCES=$(echo "$RESULT" | jq -c '.balances' 2>/dev/null || echo "[]")
fi

# If jq is available, use it for better parsing
if command -v jq &> /dev/null; then
    echo "{\"success\": true, \"address\": \"$ADDRESS\", \"balances\": $(echo "$RESULT" | jq -c '.balances')}"
else
    # Fallback: return raw result
    echo "{\"success\": true, \"address\": \"$ADDRESS\", \"raw_result\": $RESULT}"
fi
