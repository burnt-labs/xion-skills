# CosmWasm Contract Deployment Guide

Complete guide for deploying and interacting with CosmWasm smart contracts on the Xion blockchain.

## Prerequisites

- Docker installed and running (for contract optimization)
- xiond installed and configured
- Funded wallet account
- CosmWasm contract source code

## Contract Deployment Workflow

### 1. Compile and Optimize Contract

Use the CosmWasm Optimizing Compiler to create an optimized WASM binary:

```bash
docker run --rm -v "$(pwd)":/code \
  --mount type=volume,source="$(basename "$(pwd)")_cache",target=/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/optimizer:0.16.1
```

**Why Optimization is Important:**
- Reduces WASM binary size
- Lowers on-chain storage costs
- Improves execution performance

**Output Location:**
Optimized contract will be available at:
```
./artifacts/{contract_name}.wasm
```

### 2. Upload Contract to Blockchain

Upload the optimized WASM bytecode:

```bash
RES=$(xiond tx wasm store ./artifacts/cw_counter.wasm \
      --chain-id xion-testnet-2 \
      --gas-adjustment 1.3 \
      --gas-prices 0.001uxion \
      --gas auto \
      -y --output json \
      --node https://rpc.xion-testnet-2.burnt.com:443 \
      --from $WALLET)
```

**Extract Transaction Hash:**
```bash
echo $RES | jq -r '.txhash'
```

### 3. Retrieve Code ID

The Code ID is required for creating contract instances:

```bash
TXHASH="your-txhash-here"
CODE_ID=$(xiond query tx $TXHASH \
  --node https://rpc.xion-testnet-2.burnt.com:443 \
  --output json | jq -r '.events[-1].attributes[1].value')
```

**Alternative Method:**
```bash
CODE_ID=$(xiond query tx $TXHASH \
  --node https://rpc.xion-testnet-2.burnt.com:443 \
  --output json | jq -r '.events[] | select(.type == "store_code") | .attributes[] | select(.key == "code_id") | .value')
```

### 4. Instantiate Contract

Create a contract instance with initialization parameters:

```bash
MSG='{ "count": 1 }'
xiond tx wasm instantiate $CODE_ID "$MSG" \
  --from $WALLET \
  --label "cw-counter" \
  --gas-prices 0.025uxion \
  --gas auto \
  --gas-adjustment 1.3 \
  -y --no-admin \
  --chain-id xion-testnet-2 \
  --node https://rpc.xion-testnet-2.burnt.com:443
```

**Parameters:**
- `code_id`: Code ID from upload step
- `label`: Human-readable label for this instance
- `--no-admin`: No admin address (contract cannot be migrated)
- `msg`: JSON initialization message matching contract's `InstantiateMsg`

### 5. Retrieve Contract Address

Get the contract address from the instantiation transaction:

```bash
TXHASH="your-instantiate-txhash"
CONTRACT=$(xiond query tx $TXHASH \
  --node https://rpc.xion-testnet-2.burnt.com:443 \
  --output json | jq -r '.events[] | select(.type == "instantiate") | .attributes[] | select(.key == "_contract_address") | .value')
```

## Interacting with Contracts

### Query Contract State

Queries do not modify blockchain state and are free:

```bash
QUERY='{"get_count":{}}'
xiond query wasm contract-state smart $CONTRACT "$QUERY" \
  --output json \
  --node https://rpc.xion-testnet-2.burnt.com:443
```

**Common Query Patterns:**
- `{"get_config":{}}` - Get contract configuration
- `{"get_count":{}}` - Get counter value
- `{"get_balance":{"address":"xion1..."}}` - Get balance for address

### Execute Contract Messages

Executions modify contract state and require gas fees:

#### Increment Counter

```bash
TRY_INCREMENT='{"increment": {}}'
xiond tx wasm execute $CONTRACT "$TRY_INCREMENT" \
  --from $WALLET \
  --gas-prices 0.025uxion \
  --gas auto \
  --gas-adjustment 1.3 \
  -y \
  --node https://rpc.xion-testnet-2.burnt.com:443 \
  --chain-id xion-testnet-2
```

#### Reset Counter

```bash
RESET='{"reset": {"count": 0}}'
xiond tx wasm execute $CONTRACT "$RESET" \
  --from $WALLET \
  --gas-prices 0.025uxion \
  --gas auto \
  --gas-adjustment 1.3 \
  -y \
  --node https://rpc.xion-testnet-2.burnt.com:443 \
  --chain-id xion-testnet-2
```

## Example: Counter Contract

Complete workflow for the Counter contract:

```bash
# 1. Optimize
docker run --rm -v "$(pwd)":/code \
  --mount type=volume,source="$(basename "$(pwd)")_cache",target=/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/optimizer:0.16.1

# 2. Upload
RES=$(xiond tx wasm store ./artifacts/cw_counter.wasm \
      --chain-id xion-testnet-2 \
      --gas-adjustment 1.3 \
      --gas-prices 0.001uxion \
      --gas auto \
      -y --output json \
      --node https://rpc.xion-testnet-2.burnt.com:443 \
      --from $WALLET)

TXHASH=$(echo $RES | jq -r '.txhash')
CODE_ID=$(xiond query tx $TXHASH \
  --node https://rpc.xion-testnet-2.burnt.com:443 \
  --output json | jq -r '.events[-1].attributes[1].value')

# 3. Instantiate
MSG='{ "count": 1 }'
INST_RES=$(xiond tx wasm instantiate $CODE_ID "$MSG" \
  --from $WALLET \
  --label "cw-counter" \
  --gas-prices 0.025uxion \
  --gas auto \
  --gas-adjustment 1.3 \
  -y --no-admin \
  --chain-id xion-testnet-2 \
  --node https://rpc.xion-testnet-2.burnt.com:443 \
  --output json)

INST_TXHASH=$(echo $INST_RES | jq -r '.txhash')
CONTRACT=$(xiond query tx $INST_TXHASH \
  --node https://rpc.xion-testnet-2.burnt.com:443 \
  --output json | jq -r '.events[] | select(.type == "instantiate") | .attributes[] | select(.key == "_contract_address") | .value')

# 4. Query
QUERY='{"get_count":{}}'
xiond query wasm contract-state smart $CONTRACT "$QUERY" \
  --output json \
  --node https://rpc.xion-testnet-2.burnt.com:443

# 5. Execute
TRY_INCREMENT='{"increment": {}}'
xiond tx wasm execute $CONTRACT "$TRY_INCREMENT" \
  --from $WALLET \
  --gas-prices 0.025uxion \
  --gas auto \
  --gas-adjustment 1.3 \
  -y \
  --node https://rpc.xion-testnet-2.burnt.com:443 \
  --chain-id xion-testnet-2
```

## Gas Configuration

### Upload Contract
- **Gas Price**: `0.001uxion` (lower for large uploads)
- **Gas**: `auto` with `--gas-adjustment 1.3`

### Instantiate Contract
- **Gas Price**: `0.025uxion`
- **Gas**: `auto` with `--gas-adjustment 1.3`

### Execute Contract
- **Gas Price**: `0.025uxion`
- **Gas**: `auto` with `--gas-adjustment 1.3`

## Troubleshooting

### Optimization Fails
- Ensure Docker is running: `docker ps`
- Check contract directory contains valid Rust/CosmWasm project
- Verify Cargo.toml is present
- Check Docker has sufficient disk space

### Upload Fails
- Verify WASM file exists and is optimized
- Check wallet has sufficient balance
- Ensure chain-id matches target network
- Large contracts may need manual gas limit

### Instantiation Fails
- Verify Code ID is correct
- Check init-msg matches contract's InstantiateMsg schema
- Ensure wallet has sufficient balance
- Verify label is unique

### Query Fails
- Verify contract address is correct
- Check query-msg matches contract's QueryMsg schema
- Ensure node-url is accessible
- Contract may not exist if address is wrong

### Execution Fails
- Verify contract address is correct
- Check execute-msg matches contract's ExecuteMsg schema
- Ensure wallet has sufficient balance
- Contract logic may reject the message

## Best Practices

1. **Always optimize contracts** before uploading
2. **Test on testnet** before mainnet deployment
3. **Save Code IDs and addresses** for future reference
4. **Use descriptive labels** for contract instances
5. **Verify transaction status** using txhash
6. **Check gas prices** are appropriate for network
7. **Validate JSON messages** before sending transactions

## Additional Resources

- [CosmWasm Documentation](https://docs.cosmwasm.com/)
- [Xion Contract Deployment Guide](https://docs.burnt.com/xion/developers/getting-started-advanced/your-first-contract/deploy-a-cosmwasm-smart-contract)
- [Counter Contract Example](https://github.com/burnt-labs/cw-counter)
