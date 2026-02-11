# Xion Skills Collection

A collection of skills for AI Coding Agents to work with the Xion blockchain. These skills provide packaged instructions and scripts that extend Claude's capabilities for Xion blockchain development and interaction.

## Overview

This repository contains skills that enable AI assistants to:

- Install and configure the Xion CLI daemon (`xiond`)
- Manage accounts and execute transactions on Xion
- Deploy and interact with CosmWasm smart contracts

## Skills

### 1. xiond-init

**Purpose**: Install the `xiond` CLI tool when not present in the environment.

**Features**:

- Cross-platform installation support (macOS, Debian-based Linux, Red Hat-based Linux, Alpine Linux)
- Automatic OS detection
- Installation verification
- JSON output for machine readability

**Usage**:

```bash
bash /mnt/skills/user/xiond-init/scripts/install.sh
```

**When to use**: When `xiond` command is not found or needs to be installed.

### 2. xiond-usage

**Purpose**: Guide for using xiond CLI for account management, transactions, and queries.

**Features**:

- Create and manage Xion accounts
- Send tokens between accounts
- Query account balances
- Configure chain connections (testnet/mainnet)

**Scripts**:

- `create-account.sh` - Generate new key pair
- `show-account.sh` - Display account information
- `send-tokens.sh` - Send tokens between accounts
- `query-balance.sh` - Query account balance

**Usage**:

```bash
# Create account
bash /mnt/skills/user/xiond-usage/scripts/create-account.sh my-wallet

# Query balance
bash /mnt/skills/user/xiond-usage/scripts/query-balance.sh xion1abc...
```

**Prerequisites**: `xiond` must be installed (use `xiond-init` skill first).

**When to use**: When you need to create accounts, send tokens, or query balances on Xion.

### 3. xiond-wasm

**Purpose**: Deploy and interact with CosmWasm smart contracts on Xion.

**Features**:

- Optimize WASM contracts using Docker
- Upload contracts to blockchain
- Instantiate contract instances
- Query contract state
- Execute contract messages

**Scripts**:

- `optimize-contract.sh` - Compile and optimize WASM contract
- `upload-contract.sh` - Upload contract to chain
- `instantiate-contract.sh` - Create contract instance
- `query-contract.sh` - Query contract state
- `execute-contract.sh` - Execute contract messages

**Usage**:

```bash
# Optimize contract
bash /mnt/skills/user/xiond-wasm/scripts/optimize-contract.sh ./cw-counter

# Upload contract
bash /mnt/skills/user/xiond-wasm/scripts/upload-contract.sh ./artifacts/cw_counter.wasm my-wallet

# Instantiate contract
bash /mnt/skills/user/xiond-wasm/scripts/instantiate-contract.sh 123 "my-counter" '{"count":1}' my-wallet
```

**Prerequisites**:

- `xiond` must be installed (use `xiond-init` skill first)
- Docker installed and running (for optimization)
- Funded wallet account

**When to use**: When deploying or interacting with CosmWasm smart contracts on Xion.

## Installation

### For Claude Code

Copy the skills to your local skills directory:

```bash
# Install all skills
cp -r skills/* ~/.claude/skills/

# Or install individual skills
cp -r skills/xiond-init ~/.claude/skills/
cp -r skills/xiond-usage ~/.claude/skills/
cp -r skills/xiond-wasm ~/.claude/skills/
```

### For claude.ai

Add the skill to project knowledge or paste SKILL.md contents into the conversation.

## Skill Dependencies

The skills have the following dependency chain:

```
xiond-init (no dependencies)
    ↓
xiond-usage (requires xiond-init)
xiond-wasm (requires xiond-init)
```

**Important**: `xiond-usage` and `xiond-wasm` will automatically check if `xiond` is installed and prompt you to use `xiond-init` if it's not found.

## Quick Start

1. **Install xiond** (if not already installed):

   ```bash
   bash /mnt/skills/user/xiond-init/scripts/install.sh
   ```

2. **Create an account**:

   ```bash
   bash /mnt/skills/user/xiond-usage/scripts/create-account.sh my-wallet
   ```

3. **Fund your account** (via testnet faucet):
   - Visit <https://faucet.xion.burnt.com/>
   - Or use Discord faucet bot

4. **Deploy a contract**:

   ```bash
   # Optimize
   bash /mnt/skills/user/xiond-wasm/scripts/optimize-contract.sh ./my-contract
   
   # Upload
   bash /mnt/skills/user/xiond-wasm/scripts/upload-contract.sh ./artifacts/my_contract.wasm my-wallet
   
   # Instantiate
   bash /mnt/skills/user/xiond-wasm/scripts/instantiate-contract.sh <code-id> "my-contract" '{}' my-wallet
   ```

## Script Output Format

All scripts output JSON to stdout for machine readability:

```json
{
  "success": true,
  "message": "Operation completed successfully",
  ...
}
```

Status messages and progress information are written to stderr.

## Error Handling

When `xiond` is not found, scripts will return:

```json
{
  "success": false,
  "error": "xiond command not found. Please use the xiond-init skill to install xiond first."
}
```

## Network Configuration

### Testnet (Default)

- **Chain ID**: `xion-testnet-2`
- **RPC URL**: `https://rpc.xion-testnet-2.burnt.com:443`
- **Faucet**: <https://faucet.xion.burnt.com/>

### Mainnet

Check the [Xion documentation](https://docs.burnt.com/xion/developers/section-overview/public-endpoints-and-resources) for current mainnet endpoints.

## Documentation

Each skill includes:

- **SKILL.md**: Skill definition with usage instructions
- **scripts/**: Executable bash scripts for operations
- **references/**: Detailed reference documentation

For detailed information, see:

- [xiond-init references](skills/xiond-init/references/installation.md)
- [xiond-usage references](skills/xiond-usage/references/xiond-guide.md)
- [xiond-wasm references](skills/xiond-wasm/references/contract-guide.md)

## Contributing

When creating new skills, follow the guidelines in [AGENTS.md](AGENTS.md):

- Use kebab-case for skill directories
- Include SKILL.md, scripts/, and references/ directories
- Scripts should output JSON to stdout, status to stderr
- Keep SKILL.md under 500 lines
- Use `set -e` for fail-fast behavior

## Resources

- [Xion Documentation](https://docs.burnt.com/xion)
- [Xion Daemon Setup Guide](https://docs.burnt.com/xion/developers/getting-started-advanced/setup-local-environment/interact-with-xion-chain-setup-xion-daemon)
- [Contract Deployment Guide](https://docs.burnt.com/xion/developers/getting-started-advanced/your-first-contract/deploy-a-cosmwasm-smart-contract)
- [Public Endpoints](https://docs.burnt.com/xion/developers/section-overview/public-endpoints-and-resources)
- [CosmWasm Documentation](https://docs.cosmwasm.com/)
