---
name: xiond-usage
description: Guide for using xiond CLI for account management, transactions, and queries. Use when user needs to create accounts, send tokens, query balances, or configure chain connections.
---

# Xiond Usage Guide

Provides scripts and guidance for common xiond CLI operations including account management, token transfers, balance queries, and chain configuration.

## Prerequisites

**xiond must be installed before using this skill.** If `xiond` is not found in your environment, please use the `xiond-init` skill to install it first.

## How It Works

1. **Account Management**: Generate key pairs, view account information
2. **Token Operations**: Send tokens between accounts with proper gas configuration
3. **Query Operations**: Query account balances and blockchain state
4. **Chain Configuration**: Connect to different Xion chain instances (testnet, mainnet)

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

## Output

All scripts output JSON to stdout:

**Create Account:**
```json
{
  "success": true,
  "keyname": "my-wallet",
  "address": "xion1abc...",
  "pubkey": "xionpub1..."
}
```

**Show Account:**
```json
{
  "success": true,
  "keyname": "my-wallet",
  "address": "xion1abc...",
  "pubkey": "xionpub1..."
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
    {
      "denom": "uxion",
      "amount": "1000000"
    }
  ]
}
```

## Present Results to User

- **Account Creation**: "Account created successfully. Address: [address]. Save your mnemonic phrase securely!"
- **Account Info**: "Account [keyname]: Address [address], Public Key [pubkey]"
- **Token Transfer**: "Transaction successful! TxHash: [txhash]. Sent [amount] from [from] to [to]"
- **Balance Query**: "Balance for [address]: [amount] [denom]"

## Troubleshooting

**xiond Not Found:**
- If you see "xiond command not found", use the `xiond-init` skill to install xiond first
- Verify xiond is in your PATH: `which xiond`
- Check installation: `xiond version`

**Account Creation:**
- If keyname already exists, use a different name or delete the existing key first
- Ensure xiond is installed and in PATH

**Token Transfer:**
- Verify sender has sufficient balance (including gas fees)
- Check chain-id matches the target network
- Ensure node-url is accessible and correct
- Gas prices may need adjustment: `--gas-prices 0.025uxion`

**Balance Query:**
- Verify address format is correct (starts with "xion1")
- Check node-url is accessible
- For testnet, use: `https://rpc.xion-testnet-2.burnt.com:443`

**Chain Connection:**
- Find chain IDs and RPC endpoints at: https://docs.burnt.com/xion/developers/section-overview/public-endpoints-and-resources
- Testnet: `xion-testnet-2`, `https://rpc.xion-testnet-2.burnt.com:443`
- Mainnet: Check documentation for current mainnet endpoints
