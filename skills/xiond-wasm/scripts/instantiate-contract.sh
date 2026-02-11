#!/bin/bash
set -e

# Instantiate an uploaded contract
# Usage: instantiate-contract.sh <code-id> <label> <init-msg> <wallet> [chain-id] [node-url]
# Outputs JSON to stdout, status messages to stderr

# Check if xiond is installed
if ! command -v xiond &> /dev/null; then
    echo "{\"success\": false, \"error\": \"xiond command not found. Please use the xiond-init skill to install xiond first.\"}"
    exit 1
fi

if [[ $# -lt 4 ]]; then
    echo "{\"success\": false, \"error\": \"Usage: instantiate-contract.sh <code-id> <label> <init-msg> <wallet> [chain-id] [node-url]\"}"
    exit 1
fi

CODE_ID="$1"
LABEL="$2"
INIT_MSG="$3"
WALLET="$4"
CHAIN_ID="${5:-xion-testnet-2}"
NODE_URL="${6:-https://rpc.xion-testnet-2.burnt.com:443}"

# Validate JSON format
if ! echo "$INIT_MSG" | python3 -m json.tool &> /dev/null && ! echo "$INIT_MSG" | jq . &> /dev/null; then
    echo "{\"success\": false, \"error\": \"init-msg must be valid JSON\"}"
    exit 1
fi

echo "Instantiating contract with Code ID $CODE_ID..." >&2

# Instantiate the contract
RESULT=$(xiond tx wasm instantiate "$CODE_ID" "$INIT_MSG" \
    --from "$WALLET" \
    --label "$LABEL" \
    --gas-prices 0.025uxion \
    --gas auto \
    --gas-adjustment 1.3 \
    -y \
    --no-admin \
    --chain-id "$CHAIN_ID" \
    --node "$NODE_URL" \
    --output json 2>&1)

if [[ $? -ne 0 ]]; then
    echo "{\"success\": false, \"error\": \"Instantiation failed: $RESULT\"}"
    exit 1
fi

# Extract txhash
TXHASH=$(echo "$RESULT" | grep -o '"txhash":"[^"]*"' | cut -d'"' -f4 || echo "")

if [[ -z "$TXHASH" ]]; then
    TXHASH=$(echo "$RESULT" | grep "txhash:" | awk '{print $2}' | tr -d '"' || echo "")
fi

if [[ -z "$TXHASH" ]]; then
    echo "{\"success\": false, \"error\": \"Instantiation may have succeeded but failed to parse txhash\"}"
    exit 1
fi

# Query the transaction to get contract address
echo "Retrieving contract address from transaction..." >&2
TX_QUERY=$(xiond query tx "$TXHASH" \
    --node "$NODE_URL" \
    --output json 2>&1)

if [[ $? -ne 0 ]]; then
    echo "{\"success\": false, \"error\": \"Failed to query transaction: $TX_QUERY\"}"
    exit 1
fi

# Extract contract address from events
CONTRACT_ADDRESS=$(echo "$TX_QUERY" | grep -o '"_contract_address","value":"[^"]*"' | grep -o 'xion1[^"]*' || echo "")

# Try with jq if available
if [[ -z "$CONTRACT_ADDRESS" ]] && command -v jq &> /dev/null; then
    CONTRACT_ADDRESS=$(echo "$TX_QUERY" | jq -r '.events[] | select(.type == "instantiate") | .attributes[] | select(.key == "_contract_address") | .value' 2>/dev/null || echo "")
fi

if [[ -z "$CONTRACT_ADDRESS" ]]; then
    echo "{\"success\": true, \"txhash\": \"$TXHASH\", \"contract_address\": null, \"message\": \"Contract instantiated but address not found. Query transaction manually.\"}"
else
    echo "{\"success\": true, \"txhash\": \"$TXHASH\", \"contract_address\": \"$CONTRACT_ADDRESS\", \"message\": \"Contract instantiated successfully\"}"
fi
