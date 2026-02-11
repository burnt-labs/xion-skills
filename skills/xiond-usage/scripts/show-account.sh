#!/bin/bash
set -e

# Show xiond account information
# Usage: show-account.sh <keyname>
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

# Check if keyname exists
if ! xiond keys show "$KEYNAME" &> /dev/null; then
    echo "{\"success\": false, \"error\": \"Key '$KEYNAME' not found\"}"
    exit 1
fi

echo "Retrieving account information for '$KEYNAME'..." >&2

# Get address
ADDRESS=$(xiond keys show "$KEYNAME" -a 2>/dev/null || echo "")
if [[ -z "$ADDRESS" ]]; then
    echo "{\"success\": false, \"error\": \"Failed to retrieve address\"}"
    exit 1
fi

# Get pubkey
PUBKEY=$(xiond keys show "$KEYNAME" -p 2>/dev/null || echo "")

echo "{\"success\": true, \"keyname\": \"$KEYNAME\", \"address\": \"$ADDRESS\", \"pubkey\": \"$PUBKEY\"}"
