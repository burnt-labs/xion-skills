---
name: xiond-wasm
description: Deploy and interact with CosmWasm smart contracts on Xion. Use when user needs to optimize, upload, instantiate, query, or execute smart contracts.
---

# Xiond WASM Contract Operations

Provides scripts for deploying and interacting with CosmWasm smart contracts on the Xion blockchain, including contract optimization, upload, instantiation, querying, and execution.

## Prerequisites

**xiond must be installed before using this skill.** If `xiond` is not found in your environment, please use the `xiond-init` skill to install it first.

## How It Works

1. **Optimize Contract**: Compiles and optimizes WASM contract using Docker
2. **Upload Contract**: Uploads optimized WASM bytecode to the blockchain
3. **Retrieve Code ID**: Extracts Code ID from upload transaction
4. **Instantiate Contract**: Creates a contract instance with initialization parameters
5. **Query Contract**: Queries contract state without modifying blockchain
6. **Execute Contract**: Executes contract messages that modify state

## Usage

### Optimize Contract

```bash
bash /mnt/skills/user/xiond-wasm/scripts/optimize-contract.sh <contract-dir>
```

**Arguments:**

- `contract-dir` - Directory containing the CosmWasm contract source (required)

**Example:**

```bash
bash /mnt/skills/user/xiond-wasm/scripts/optimize-contract.sh ./cw-counter
```

### Upload Contract

```bash
bash /mnt/skills/user/xiond-wasm/scripts/upload-contract.sh <wasm-file> <wallet> [chain-id] [node-url]
```

**Arguments:**

- `wasm-file` - Path to optimized .wasm file (required)
- `wallet` - Wallet key name or address (required)
- `chain-id` - Chain ID (optional, defaults to xion-testnet-2)
- `node-url` - RPC node URL (optional, defaults to testnet RPC)

**Example:**

```bash
bash /mnt/skills/user/xiond-wasm/scripts/upload-contract.sh ./artifacts/cw_counter.wasm my-wallet
```

### Instantiate Contract

```bash
bash /mnt/skills/user/xiond-wasm/scripts/instantiate-contract.sh <code-id> <label> <init-msg> <wallet> [chain-id] [node-url]
```

**Arguments:**

- `code-id` - Code ID from upload transaction (required)
- `label` - Human-readable label for contract instance (required)
- `init-msg` - JSON initialization message (required)
- `wallet` - Wallet key name or address (required)
- `chain-id` - Chain ID (optional, defaults to xion-testnet-2)
- `node-url` - RPC node URL (optional, defaults to testnet RPC)

**Example:**

```bash
bash /mnt/skills/user/xiond-wasm/scripts/instantiate-contract.sh 123 "my-counter" '{"count":1}' my-wallet
```

### Query Contract

```bash
bash /mnt/skills/user/xiond-wasm/scripts/query-contract.sh <contract-address> <query-msg> [node-url]
```

**Arguments:**

- `contract-address` - Contract address (required)
- `query-msg` - JSON query message (required)
- `node-url` - RPC node URL (optional, defaults to testnet RPC)

**Example:**

```bash
bash /mnt/skills/user/xiond-wasm/scripts/query-contract.sh xion1abc... '{"get_count":{}}'
```

### Execute Contract

```bash
bash /mnt/skills/user/xiond-wasm/scripts/execute-contract.sh <contract-address> <execute-msg> <wallet> [chain-id] [node-url]
```

**Arguments:**

- `contract-address` - Contract address (required)
- `execute-msg` - JSON execute message (required)
- `wallet` - Wallet key name or address (required)
- `chain-id` - Chain ID (optional, defaults to xion-testnet-2)
- `node-url` - RPC node URL (optional, defaults to testnet RPC)

**Example:**

```bash
bash /mnt/skills/user/xiond-wasm/scripts/execute-contract.sh xion1abc... '{"increment":{}}' my-wallet
```

## Output

All scripts output JSON to stdout:

**Optimize Contract:**
```json
{
  "success": true,
  "wasm_file": "./artifacts/cw_counter.wasm",
  "message": "Contract optimized successfully"
}
```

**Upload Contract:**
```json
{
  "success": true,
  "txhash": "ABC123...",
  "code_id": 123,
  "message": "Contract uploaded successfully"
}
```

**Instantiate Contract:**
```json
{
  "success": true,
  "txhash": "DEF456...",
  "contract_address": "xion1abc...",
  "message": "Contract instantiated successfully"
}
```

**Query Contract:**
```json
{
  "success": true,
  "contract": "xion1abc...",
  "result": {
    "count": 5
  }
}
```

**Execute Contract:**
```json
{
  "success": true,
  "txhash": "GHI789...",
  "contract": "xion1abc...",
  "message": "Transaction executed successfully"
}
```

## Present Results to User

- **Optimization**: "Contract optimized successfully. WASM file: [path]"
- **Upload**: "Contract uploaded successfully! Code ID: [code_id], TxHash: [txhash]"
- **Instantiation**: "Contract instantiated successfully! Address: [address], TxHash: [txhash]"
- **Query**: "Query result: [formatted JSON result]"
- **Execution**: "Transaction executed successfully! TxHash: [txhash]"

## Troubleshooting

**xiond Not Found:**
- If you see "xiond command not found", use the `xiond-init` skill to install xiond first
- Verify xiond is in your PATH: `which xiond`
- Check installation: `xiond version`

**Optimization:**
- Ensure Docker is installed and running
- Verify contract directory contains valid CosmWasm contract
- Check Docker has access to volumes: `docker ps` should work
- Optimization may take several minutes for large contracts

**Upload:**
- Verify WASM file exists and is optimized
- Ensure wallet has sufficient balance for gas fees
- Check chain-id matches target network
- Large contracts may require higher gas limits

**Instantiation:**
- Verify Code ID is correct (from upload transaction)
- Ensure init-msg matches contract's expected format
- Check wallet has sufficient balance
- Verify label is unique and descriptive

**Query:**
- Verify contract address is correct
- Ensure query-msg matches contract's query schema
- Check node-url is accessible
- Contract may not exist if address is incorrect

**Execution:**
- Verify contract address is correct
- Ensure execute-msg matches contract's execute schema
- Check wallet has sufficient balance (including gas)
- Transaction may fail if contract logic rejects the message

## Additional Prerequisites

- Docker installed and running (for optimization)
- Funded wallet account
- CosmWasm contract source code (for optimization)
