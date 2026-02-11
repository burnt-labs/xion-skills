# Xiond Usage Reference Guide

Comprehensive guide for using the `xiond` CLI daemon to interact with the Xion blockchain.

## Prerequisites

- `xiond` installed (see `xiond-init` skill)
- Funded account for transactions
- Network connectivity to Xion RPC nodes

## Account Management

### Generate a New Key Pair

```bash
xiond keys add <keyname>
```

Replace `<keyname>` with a name of your choice for easy reference.

**Example:**
```bash
xiond keys add my-wallet
```

**Output:**
- A mnemonic phrase (save this securely!)
- Public key
- Address (derived from public key)

### Retrieve Public Key and Address

```bash
xiond keys show <keyname>
```

**Example:**
```bash
xiond keys show my-wallet
```

### List All Keys

```bash
xiond keys list
```

## Funding Your Account

Your account is not fully registered on-chain until it is involved in a transaction. Fund your account using:

### Testnet Tokens

- **Discord Faucet**: Request tokens via the faucet bot in XION Discord
- **Faucet Web Page**: Visit https://faucet.xion.burnt.com/

### Mainnet Tokens

Acquire XION tokens through decentralized or centralized exchanges.

## Connecting to Different Chain Instances

By default, `xiond` uses a local network node. To connect to testnet or mainnet:

### Finding Chain IDs and RPC Nodes

Check the [Public Endpoints and Resources](https://docs.burnt.com/xion/developers/section-overview/public-endpoints-and-resources) documentation for:
- Chain IDs for all Xion chains
- Available public RPC nodes

### Testnet Configuration

- **Chain ID**: `xion-testnet-2`
- **RPC URL**: `https://rpc.xion-testnet-2.burnt.com:443`

## Executing Transactions

### Sending Tokens

```bash
xiond tx bank send <your-wallet> <recipient-address> <amount>uxion \
  --chain-id <target-chain-id> \
  --node <node-url> \
  --from <your-wallet> \
  --gas-prices 0.025uxion \
  --gas auto \
  --gas-adjustment 1.3 \
  -y
```

**Example:**
```bash
xiond tx bank send my-wallet xion1abc... 1000uxion \
  --chain-id xion-testnet-2 \
  --node https://rpc.xion-testnet-2.burnt.com:443 \
  --from my-wallet \
  --gas-prices 0.025uxion \
  --gas auto \
  --gas-adjustment 1.3 \
  -y
```

**Transaction Output:**
- `txhash`: Transaction hash for tracking
- `code`: 0 indicates success
- `height`: Block height when included

### Querying Transaction Status

```bash
xiond query tx <txhash> --node <node-url>
```

## Executing Queries

Queries don't require `--chain-id`, only `--node`.

### Query Account Balance

```bash
xiond query bank balances <wallet-address> --node <node-url>
```

**Example:**
```bash
xiond query bank balances xion1abc... --node https://rpc.xion-testnet-2.burnt.com:443
```

**Output:**
```yaml
balances:
- amount: "1223782"
  denom: uxion
pagination:
  total: "1"
```

### Query Account Information

```bash
xiond query auth account <address> --node <node-url>
```

### Query Chain Status

```bash
xiond status --node <node-url>
```

## Gas Configuration

### Gas Prices

- Testnet: `0.025uxion` (recommended)
- Mainnet: Check current gas prices

### Gas Estimation

- `--gas auto`: Automatically estimate gas
- `--gas-adjustment 1.3`: Add 30% buffer to estimated gas
- `--gas 200000`: Set specific gas limit

## Common Commands

### View Available Commands

```bash
xiond --help
```

### View Command Help

```bash
xiond <command> --help
```

### Initialize Local Node

```bash
xiond init <moniker> --chain-id <chain-id>
```

### Start Local Node

```bash
xiond start
```

## Best Practices

1. **Always verify addresses** before sending tokens
2. **Test on testnet first** before mainnet operations
3. **Save mnemonic phrases securely** - they cannot be recovered
4. **Use appropriate gas prices** for your target network
5. **Verify transaction status** using txhash after sending
6. **Keep xiond updated** to latest version

## Troubleshooting

### Transaction Fails

- Check account balance (including gas fees)
- Verify chain-id matches target network
- Ensure node-url is accessible
- Check gas prices are appropriate

### Query Fails

- Verify address format (starts with "xion1")
- Check node-url is accessible
- Ensure network connectivity

### Key Not Found

- List all keys: `xiond keys list`
- Verify keyname spelling
- Check if key was created in different xiond home directory

## Additional Resources

- [Xion Documentation](https://docs.burnt.com/xion)
- [Xion Daemon Setup Guide](https://docs.burnt.com/xion/developers/getting-started-advanced/setup-local-environment/interact-with-xion-chain-setup-xion-daemon)
- [Public Endpoints](https://docs.burnt.com/xion/developers/section-overview/public-endpoints-and-resources)
