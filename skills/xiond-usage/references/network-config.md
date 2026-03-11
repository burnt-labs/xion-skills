# Xion Network Configuration

This document provides the network configuration for Xion testnet and mainnet.

## Network Overview

| Network | Chain ID | Description |
|---------|----------|-------------|
| **Testnet** | `xion-testnet-2` | Safe environment for experimentation and testing |
| **Mainnet** | `xion-mainnet-1` | Production network with real assets |

## Testnet Configuration

**Chain ID:** `xion-testnet-2`

| Endpoint Type | URL |
|--------------|-----|
| RPC | `https://rpc.xion-testnet-2.burnt.com:443` |
| API/REST | `https://api.xion-testnet-2.burnt.com` |
| gRPC | `grpc.xion-testnet-2.burnt.com:443` |
| WebSocket | `wss://rpc.xion-testnet-2.burnt.com:443/websocket` |

**Faucet:** https://faucet.xion.burnt.com/

**Explorer:** https://explorer.burnt.com/xion-testnet

## Mainnet Configuration

**Chain ID:** `xion-mainnet-1`

| Endpoint Type | URL |
|--------------|-----|
| RPC | `https://rpc.xion-mainnet-1.burnt.com` |
| API/REST | `https://api.xion-mainnet-1.burnt.com` |
| gRPC | `grpc.xion-mainnet-1.burnt.com:443` |
| WebSocket | `wss://rpc.xion-mainnet-1.burnt.com/websocket` |

**Explorer:** https://explorer.burnt.com/xion-mainnet

## Using Network Configuration in Scripts

All scripts support specifying the network in multiple ways:

### Method 1: `--network` flag (Recommended)

```bash
# Use testnet (default)
bash script.sh --network testnet

# Use mainnet
bash script.sh --network mainnet
```

### Method 2: Environment Variable

```bash
export XION_NETWORK=mainnet
bash script.sh
```

### Method 3: Direct Chain ID and Node URL

For advanced use cases, you can still specify exact chain-id and node-url:

```bash
bash script.sh ... xion-mainnet-1 https://rpc.xion-mainnet-1.burnt.com
```

## Gas Configuration

### Testnet
- **Gas Price:** `0.025uxion` (recommended)
- **Gas Adjustment:** `1.3`

### Mainnet
- **Gas Price:** Check current network conditions
- **Gas Adjustment:** `1.3` or higher for complex transactions

## Additional Resources

- [Xion Documentation](https://docs.burnt.com/xion)
- [Public Endpoints](https://docs.burnt.com/xion/developers/section-overview/public-endpoints-and-resources)
- [Cosmos Chain Registry - Xion Mainnet](https://github.com/cosmos/chain-registry/blob/master/xion/chain.json)
- [Cosmos Chain Registry - Xion Testnet](https://github.com/cosmos/chain-registry/blob/master/testnets/xion/chain.json)
