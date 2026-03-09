# Eviction Vault

A secure, modular multi-signature vault contract with timelock, merkle-based claims, and pause functionality.

## Architecture

The contract has been refactored from a monolithic structure into modular components:

- **MultiSig.sol**: Handles multi-signature transactions with timelock.
- **Vault.sol**: Manages deposits and withdrawals.
- **Claim.sol**: Handles merkle proof-based claims.
- **Pausable.sol**: Provides pause/unpause functionality.
- **EvictionVault.sol**: Main contract inheriting all modules.

## Security Fixes Implemented

1. **setMerkleRoot Callable by Anyone**: Now requires multi-signature confirmation via transaction submission.
2. **emergencyWithdrawAll Public Drain**: Removed the function to prevent unauthorized drains.
3. **pause/unpause Single Owner Control**: Maintained as owner-only, but can be extended to multi-sig if needed.
4. **receive() Uses tx.origin**: Changed to use `msg.sender` for security.
5. **withdraw & claim Uses .transfer**: Replaced with `.call{value: }("")` for better gas handling and security.
6. **Timelock Execution**: Verified and maintained correct implementation.

## Current State

- Modular architecture implemented.
- All critical vulnerabilities mitigated.
- Basic tests passing.
- Ready for further development and auditing.

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Deploy

Use the script in `script/` to deploy.
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
