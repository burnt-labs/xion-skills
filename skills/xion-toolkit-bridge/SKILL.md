---
name: xion-toolkit-bridge
version: 1.0.0
description: |
  MetaAccount development with xion-toolkit.
  For gasless transactions, OAuth2 authentication, and Treasury management.
  
  Use this when the user needs MetaAccount features instead of traditional xiond CLI.
  
  Triggers: MetaAccount, gasless, 无 gas, OAuth2, Treasury, session key,
  fee grant, authz grant configuration, xion toolkit, xion-agent-toolkit.
---

# xion-toolkit Bridge

For MetaAccount-based development (gasless, OAuth2, Treasury):

👉 **Use xion-toolkit**: https://github.com/burnt-labs/xion-agent-toolkit

## Quick Comparison

| Feature | xion-toolkit | xiond (xion-skills) |
|---------|--------------|---------------------|
| Auth | OAuth2 + MetaAccount | Mnemonic |
| Gas | Gasless | Paid |
| Treasury | Full support | Limited |
| Contracts | Execute only | Full lifecycle |
| Queries | Basic | Advanced |

## When to Use Each

### Use xion-toolkit for:
- Building applications with MetaAccount
- OAuth2-based authentication
- Gasless transactions
- Treasury contract management
- Fee grants and authz configuration

### Use xion-skills (xiond) for:
- CosmWasm contract deployment
- Advanced chain queries
- Validator operations
- Mnemonic-based wallet management
- Contract migration

## Get xion-toolkit

Install via skills.sh (recommended):

```bash
npx skills add burnt-labs/xion-agent-toolkit
```

Or visit for documentation and examples:
👉 https://github.com/burnt-labs/xion-agent-toolkit
