#!/bin/bash
# Network configuration helper for Xion scripts
# Source this file to get network resolution functions

# Network configurations
XION_TESTNET_CHAIN_ID="xion-testnet-2"
XION_TESTNET_RPC="https://rpc.xion-testnet-2.burnt.com:443"
XION_TESTNET_API="https://api.xion-testnet-2.burnt.com"

XION_MAINNET_CHAIN_ID="xion-mainnet-1"
XION_MAINNET_RPC="https://rpc.xion-mainnet-1.burnt.com"
XION_MAINNET_API="https://api.xion-mainnet-1.burnt.com"

XION_LOCAL_CHAIN_ID="xion-local"
XION_LOCAL_RPC="http://localhost:26657"
XION_LOCAL_API="http://localhost:1317"

# Resolve network settings
# Usage: resolve_network [network_name]
# Sets: CHAIN_ID, NODE_URL
resolve_network() {
    local network="${1:-${XION_NETWORK:-testnet}}"
    
    case "$network" in
        testnet|test)
            CHAIN_ID="$XION_TESTNET_CHAIN_ID"
            NODE_URL="$XION_TESTNET_RPC"
            ;;
        mainnet|main|prod)
            CHAIN_ID="$XION_MAINNET_CHAIN_ID"
            NODE_URL="$XION_MAINNET_RPC"
            ;;
        local|dev)
            CHAIN_ID="$XION_LOCAL_CHAIN_ID"
            NODE_URL="$XION_LOCAL_RPC"
            ;;
        *)
            echo "Unknown network: $network. Use 'testnet', 'mainnet', or 'local'." >&2
            return 1
            ;;
    esac
}

# Parse network flag from arguments
# Usage: parse_network_args "$@"
# Returns remaining args (without --network flag) in PARSED_ARGS array
# Sets: NETWORK_NAME
parse_network_args() {
    NETWORK_NAME="${XION_NETWORK:-testnet}"
    PARSED_ARGS=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --network|-n)
                NETWORK_NAME="$2"
                shift 2
                ;;
            --network=*)
                NETWORK_NAME="${1#*=}"
                shift
                ;;
            *)
                PARSED_ARGS+=("$1")
                shift
                ;;
        esac
    done
}
