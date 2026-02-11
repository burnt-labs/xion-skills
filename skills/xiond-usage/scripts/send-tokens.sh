#!/bin/bash
set -e

# Send tokens between accounts using xiond
# Usage: send-tokens.sh <from> <to> <amount> [chain-id] [node-url]
# Outputs JSON to stdout, status messages to stderr

# Check if xiond is installed
if ! command -v xiond &> /dev/null; then
    echo "{\"success\": false, \"error\": \"xiond command not found. Please use the xiond-init skill to install xiond first.\"}"
    exit 1
fi

if [[ $# -lt 3 ]]; then
    echo "{\"success\": false, \"error\": \"Usage: send-tokens.sh <from> <to> <amount> [chain-id] [node-url]\"}"
    exit 1
fi

FROM="$1"
TO="$2"
AMOUNT="$3"
CHAIN_ID="${4:-xion-testnet-2}"
NODE_URL="${5:-https://rpc.xion-testnet-2.burnt.com:443}"

echo "Sending $AMOUNT from $FROM to $TO..." >&2

# Execute the transaction
RESULT=$(xiond tx bank send "$FROM" "$TO" "$AMOUNT" \
    --chain-id "$CHAIN_ID" \
    --node "$NODE_URL" \
    --from "$FROM" \
    --gas-prices 0.025uxion \
    --gas auto \
    --gas-adjustment 1.3 \
    -y \
    --output json 2>&1)

if [[ $? -ne 0 ]]; then
    echo "{\"success\": false, \"error\": \"Transaction failed: $RESULT\"}"
    exit 1
fi

# Extract txhash
TXHASH=$(echo "$RESULT" | grep -o '"txhash":"[^"]*"' | cut -d'"' -f4 || echo "")

if [[ -z "$TXHASH" ]]; then
    # Try alternative parsing
    TXHASH=$(echo "$RESULT" | grep "txhash:" | awk '{print $2}' | tr -d '"' || echo "")
fi

if [[ -z "$TXHASH" ]]; then
    echo "{\"success\": false, \"error\": \"Transaction may have succeeded but failed to parse txhash\"}"
    exit 1
fi

echo "{\"success\": true, \"txhash\": \"$TXHASH\", \"from\": \"$FROM\", \"to\": \"$TO\", \"amount\": \"$AMOUNT\", \"chain_id\": \"$CHAIN_ID\"}"
