---
name: xiond-usage
description: Day-to-day Xion account operations using `xiond` CLI. Use this proactively whenever the user mentions wallet, key, account, address, balance, transfer, send tokens, transaction, faucet, seed phrase, mnemonic, recover account, or any account management task. Also use for listing accounts, restoring wallets from mnemonic, checking transaction status, querying txhash, or chain information. Covers create/show/list/restore keys, send/query tokens, check balances, and chain status queries.
---

# Xiond Usage Guide

Provides scripts and guidance for common xiond CLI operations including account management, token transfers, balance queries, transaction tracking, and chain status.

## Prerequisites

**xiond must be installed before using this skill.** If `xiond` is not found in your environment, please use the `xiond-init` skill to install it first.

## Compatibility

- Requires `bash` and `python3`
- Scripts print **machine-readable JSON to stdout** and progress/errors to stderr
- Supports testnet, mainnet, and local network configurations

## Network Selection

All scripts support selecting the target network:

### Using `--network` flag (Recommended)

```bash
# Use testnet (default)
bash script.sh --network testnet

# Use mainnet
bash script.sh --network mainnet

# Use local development node
bash script.sh --network local
```

### Using environment variable

```bash
export XION_NETWORK=mainnet
bash script.sh
```

### Network Endpoints

| Network | Chain ID | RPC Endpoint |
|---------|----------|--------------|
| testnet | `xion-testnet-2` | `https://rpc.xion-testnet-2.burnt.com:443` |
| mainnet | `xion-mainnet-1` | `https://rpc.xion-mainnet-1.burnt.com` |
| local | `xion-local` | `http://localhost:26657` |

For detailed network configuration, see `references/network-config.md`.

## How It Works

1. **Account Management**: Generate, restore, list, and view key pairs
2. **Token Operations**: Send tokens between accounts with proper gas configuration
3. **Query Operations**: Query account balances, transaction status, and chain state
4. **Chain Information**: Get network status and sync information

## Usage

### Create Account

```bash
bash /mnt/skills/user/xiond-usage/scripts/create-account.sh <keyname>
```

**Arguments:**
- `keyname` - Name for the key pair (required)

**Example:**
```bash
bash /mnt/skills/user/xiond-usage/scripts/create-account.sh my-wallet
```

### Restore Account from Mnemonic

```bash
bash /mnt/skills/user/xiond-usage/scripts/restore-account.sh <keyname>
```

**Arguments:**
- `keyname` - Name for the restored key (required)

You will be prompted to enter your mnemonic phrase (24 words).

**Example:**
```bash
bash /mnt/skills/user/xiond-usage/scripts/restore-account.sh recovered-wallet
```

### List All Accounts

```bash
bash /mnt/skills/user/xiond-usage/scripts/list-accounts.sh
```

Lists all keys stored in the local keyring.

### Show Account

```bash
bash /mnt/skills/user/xiond-usage/scripts/show-account.sh <keyname>
```

**Arguments:**
- `keyname` - Name of the key to display (required)

**Example:**
```bash
bash /mnt/skills/user/xiond-usage/scripts/show-account.sh my-wallet
```

### Send Tokens

```bash
bash /mnt/skills/user/xiond-usage/scripts/send-tokens.sh <from> <to> <amount> [chain-id] [node-url]
```

**Arguments:**
- `from` - Sender key name or address (required)
- `to` - Recipient address (required)
- `amount` - Amount to send (e.g., "1000uxion") (required)
- `chain-id` - Chain ID (optional, defaults to xion-testnet-2)
- `node-url` - RPC node URL (optional, defaults to testnet RPC)

**Example:**
```bash
bash /mnt/skills/user/xiond-usage/scripts/send-tokens.sh my-wallet xion1abc... 1000uxion
```

### Query Balance

```bash
bash /mnt/skills/user/xiond-usage/scripts/query-balance.sh <address> [node-url]
```

**Arguments:**
- `address` - Xion address to query (required)
- `node-url` - RPC node URL (optional, defaults to testnet RPC)

**Example:**
```bash
bash /mnt/skills/user/xiond-usage/scripts/query-balance.sh xion1abc...
```

### Query Transaction

```bash
bash /mnt/skills/user/xiond-usage/scripts/query-tx.sh <txhash> [node-url]
```

**Arguments:**
- `txhash` - Transaction hash (required)
- `node-url` - RPC node URL (optional, defaults to testnet RPC)

**Example:**
```bash
bash /mnt/skills/user/xiond-usage/scripts/query-tx.sh ABC123DEF456...
```

### Query Chain Info

```bash
bash /mnt/skills/user/xiond-usage/scripts/query-chain-info.sh [node-url]
```

**Arguments:**
- `node-url` - RPC node URL (optional, defaults to testnet RPC)

**Example:**
```bash
bash /mnt/skills/user/xiond-usage/scripts/query-chain-info.sh
```

## Output

All scripts output JSON to stdout:

**Create/Restore Account:**
```json
{
  "success": true,
  "keyname": "my-wallet",
  "address": "xion1abc...",
  "pubkey": "xionpub1..."
}
```

**List Accounts:**
```json
{
  "success": true,
  "count": 2,
  "accounts": [
    {"name": "wallet1", "address": "xion1abc...", "type": "local"},
    {"name": "wallet2", "address": "xion1def...", "type": "local"}
  ]
}
```

**Send Tokens:**
```json
{
  "success": true,
  "txhash": "ABC123...",
  "from": "xion1abc...",
  "to": "xion1def...",
  "amount": "1000uxion"
}
```

**Query Balance:**
```json
{
  "success": true,
  "address": "xion1abc...",
  "balances": [
    {"denom": "uxion", "amount": "1000000"}
  ]
}
```

**Query Transaction:**
```json
{
  "success": true,
  "txhash": "ABC123...",
  "status": "success",
  "code": 0,
  "height": "12345",
  "gas_used": "50000"
}
```

**Query Chain Info:**
```json
{
  "success": true,
  "chain_id": "xion-testnet-2",
  "block_height": "1234567",
  "catching_up": false
}
```

## Present Results to User

- **Account Creation/Restore**: "Account [keyname] ready. Address: [address]. Save your mnemonic securely!"
- **List Accounts**: "Found [count] accounts: [list names]"
- **Token Transfer**: "Transaction submitted! TxHash: [txhash]. Sent [amount] from [from] to [to]"
- **Balance Query**: "Balance for [address]: [amount] [denom]"
- **Transaction Query**: "Transaction [txhash]: [status] at height [height]"
- **Chain Info**: "Connected to [chain_id] at height [block_height]"

## Getting Testnet Tokens

Your account needs tokens before making transactions. For testnet:

1. **Faucet Web**: Visit https://faucet.xion.burnt.com/
2. **Discord**: Request tokens via the faucet bot in Xion Discord

## Troubleshooting

**xiond Not Found:**
- Use the `xiond-init` skill to install xiond first
- Verify xiond is in your PATH: `which xiond`

**Account Issues:**
- If keyname exists, use a different name or delete existing key first
- Mnemonic restore requires exactly 24 words

**Token Transfer:**
- Verify sender has sufficient balance (including gas fees)
- Check chain-id matches target network
- Gas prices may need adjustment

**Query Issues:**
- Verify address format (starts with "xion1")
- Check node-url is accessible
- Testnet: `https://rpc.xion-testnet-2.burnt.com:443`

**Chain Connection:**
- Find endpoints at: https://docs.burnt.com/xion/developers/section-overview/public-endpoints-and-resources
- Testnet: `xion-testnet-2`, `https://rpc.xion-testnet-2.burnt.com:443`

## References

- `references/xiond-guide.md` — Deeper CLI notes, gas flags, and advanced usage
