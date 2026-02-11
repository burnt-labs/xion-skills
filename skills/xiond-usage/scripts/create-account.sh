#!/bin/bash
set -e

# Create a new xiond account key pair
# Usage: create-account.sh <keyname>
# Outputs JSON to stdout, status messages to stderr

# Check if xiond is installed
if ! command -v xiond &> /dev/null; then
    echo "{\"success\": false, \"error\": \"xiond command not found. Please use the xiond-init skill to install xiond first.\"}"
    exit 1
fi

if [[ $# -lt 1 ]]; then
    echo "{\"success\": false, \"error\": \"keyname is required\"}"
    exit 1
fi

KEYNAME="$1"

# Check if keyname already exists
if xiond keys show "$KEYNAME" &> /dev/null; then
    echo "{\"success\": false, \"error\": \"Key '$KEYNAME' already exists\"}"
    exit 1
fi

# Create the key (non-interactive mode)
echo "Creating account '$KEYNAME'..." >&2
OUTPUT=$(xiond keys add "$KEYNAME" --output json 2>&1)

if [[ $? -ne 0 ]]; then
    echo "{\"success\": false, \"error\": \"Failed to create account: $OUTPUT\"}"
    exit 1
fi

# Extract address and pubkey from output
ADDRESS=$(echo "$OUTPUT" | grep -o '"address":"[^"]*"' | cut -d'"' -f4 || echo "")
PUBKEY=$(echo "$OUTPUT" | grep -o '"pubkey":"[^"]*"' | cut -d'"' -f4 || echo "")

# If JSON parsing failed, try alternative method
if [[ -z "$ADDRESS" ]]; then
    ADDRESS=$(xiond keys show "$KEYNAME" -a 2>/dev/null || echo "")
    PUBKEY=$(xiond keys show "$KEYNAME" -p 2>/dev/null || echo "")
fi

if [[ -z "$ADDRESS" ]]; then
    echo "{\"success\": false, \"error\": \"Account created but failed to retrieve address\"}"
    exit 1
fi

echo "{\"success\": true, \"keyname\": \"$KEYNAME\", \"address\": \"$ADDRESS\", \"pubkey\": \"$PUBKEY\"}"
