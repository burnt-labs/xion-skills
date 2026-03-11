---
name: xiond-wasm
description: Deploy, interact with, and manage CosmWasm smart contracts on Xion using `xiond`. Use this proactively whenever the user mentions smart contracts, WASM, CosmWasm, contract deployment, Code ID, instantiate, execute, query contract, migrate contract, upgrade contract, or any blockchain contract interaction. Covers the full contract lifecycle: optimize → upload → instantiate → query/execute → migrate/upgrade. Also use for listing uploaded codes and querying contract metadata.
---

# Xiond WASM Contract Operations

Provides scripts for deploying and interacting with CosmWasm smart contracts on the Xion blockchain. Covers the complete contract lifecycle from optimization through migration.

## Prerequisites

**xiond must be installed before using this skill.** If `xiond` is not found in your environment, please use the `xiond-init` skill to install it first.

## Compatibility

- Requires `bash` and `python3`
- Optimization requires Docker running locally
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

## How It Works

1. **Optimize Contract**: Compiles and optimizes WASM contract using Docker
2. **Upload Contract**: Uploads optimized WASM bytecode to the blockchain
3. **List Codes**: View all uploaded contract codes on the chain
4. **Instantiate Contract**: Creates a contract instance with initialization parameters
5. **Query Contract**: Queries contract state without modifying blockchain
6. **Execute Contract**: Executes contract messages that modify state
7. **Migrate Contract**: Upgrades contract to a new code version
8. **Contract Info**: Query contract metadata and configuration

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
bash /mnt/skills/user/xiond-wasm/scripts/upload-contract.sh <wasm-file> <wallet> [--network testnet|mainnet|local]
```

**Arguments:**
- `wasm-file` - Path to optimized .wasm file (required)
- `wallet` - Wallet key name or address (required)
- `--network` - Target network (optional, default: testnet)

**Examples:**
```bash
# Upload to testnet (default)
bash /mnt/skills/user/xiond-wasm/scripts/upload-contract.sh ./artifacts/cw_counter.wasm my-wallet

# Upload to mainnet
bash /mnt/skills/user/xiond-wasm/scripts/upload-contract.sh ./artifacts/cw_counter.wasm my-wallet --network mainnet
```

### List Uploaded Codes

```bash
bash /mnt/skills/user/xiond-wasm/scripts/list-codes.sh [node-url]
```

**Arguments:**
- `node-url` - RPC node URL (optional, defaults to testnet RPC)

**Example:**
```bash
bash /mnt/skills/user/xiond-wasm/scripts/list-codes.sh
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

### Query Contract State

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

### Query Contract Info

```bash
bash /mnt/skills/user/xiond-wasm/scripts/query-contract-info.sh <contract-address> [node-url]
```

**Arguments:**
- `contract-address` - Contract address (required)
- `node-url` - RPC node URL (optional, defaults to testnet RPC)

**Example:**
```bash
bash /mnt/skills/user/xiond-wasm/scripts/query-contract-info.sh xion1abc...
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

### Migrate Contract

```bash
bash /mnt/skills/user/xiond-wasm/scripts/migrate-contract.sh <contract-address> <new-code-id> <migrate-msg> <wallet> [chain-id] [node-url]
```

**Arguments:**
- `contract-address` - Contract address to migrate (required)
- `new-code-id` - New Code ID to migrate to (required)
- `migrate-msg` - JSON migration message (required, can be `{}`)
- `wallet` - Wallet key name or address (must be contract admin)
- `chain-id` - Chain ID (optional, defaults to xion-testnet-2)
- `node-url` - RPC node URL (optional, defaults to testnet RPC)

**Example:**
```bash
bash /mnt/skills/user/xiond-wasm/scripts/migrate-contract.sh xion1abc... 456 '{}' admin-wallet
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

**List Codes:**
```json
{
  "success": true,
  "count": 5,
  "codes": [
    {"code_id": "123", "creator": "xion1...", "data_hash": "..."}
  ]
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
  "result": {"count": 5}
}
```

**Contract Info:**
```json
{
  "success": true,
  "contract_address": "xion1abc...",
  "code_id": "123",
  "creator": "xion1...",
  "admin": "xion1...",
  "label": "my-counter"
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

**Migrate Contract:**
```json
{
  "success": true,
  "txhash": "JKL012...",
  "contract": "xion1abc...",
  "new_code_id": "456",
  "message": "Contract migrated successfully"
}
```

## Present Results to User

- **Optimization**: "Contract optimized. WASM file: [path]"
- **Upload**: "Contract uploaded! Code ID: [code_id], TxHash: [txhash]"
- **List Codes**: "Found [count] uploaded codes: [list code_ids]"
- **Instantiation**: "Contract instantiated! Address: [address], TxHash: [txhash]"
- **Query**: "Query result: [formatted JSON]"
- **Contract Info**: "Contract [address]: Code ID [code_id], Creator: [creator]"
- **Execution**: "Transaction submitted! TxHash: [txhash]"
- **Migration**: "Contract migrated to Code ID [new_code_id]! TxHash: [txhash]"

## Troubleshooting

**xiond Not Found:**
- Use the `xiond-init` skill to install xiond first
- Verify: `which xiond && xiond version`

**Optimization:**
- Ensure Docker is installed and running: `docker ps`
- Verify contract directory contains valid CosmWasm project
- May take several minutes for large contracts

**Upload:**
- Verify WASM file exists and is optimized
- Ensure wallet has sufficient balance for gas fees
- Large contracts may require higher gas limits

**Instantiation:**
- Verify Code ID is correct (from upload or list-codes)
- Ensure init-msg matches contract's expected schema
- Verify label is unique

**Query:**
- Verify contract address format (starts with "xion1")
- Ensure query-msg matches contract's query schema
- Contract may not exist if address is incorrect

**Execution:**
- Verify contract address and execute-msg schema
- Check wallet has sufficient balance (including gas)
- Transaction may fail if contract logic rejects the message

**Migration:**
- Wallet must be the contract admin
- Contract must have been instantiated with an admin
- New code must be uploaded first
- migrate-msg must match new code's MigrateMsg schema

## Contract Migration Notes

Migration allows upgrading a contract's logic while preserving its address and state:

1. Upload the new contract code (get new Code ID)
2. Run migrate with the new Code ID
3. The contract address stays the same, but uses new code

**Requirements:**
- Contract must have an admin set (not `--no-admin`)
- Only the admin can migrate
- Both old and new code must support migration

## Additional Prerequisites

- Docker installed and running (for optimization)
- Funded wallet account
- CosmWasm contract source code (for optimization)

## References

- `references/contract-guide.md` — End-to-end deployment walkthrough, examples, and troubleshooting
