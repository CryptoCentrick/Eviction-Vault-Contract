# EvictionVault – Modular Yield Vault with Multisig & Merkle Claim

## Overview

EvictionVault is a secure, modular Ethereum vault designed to manage deposits, withdrawals, emergency actions, and airdrop-style ETH claims. The architecture is built to mitigate critical vulnerabilities, enforce multisignature governance, and provide extensibility via modular design.

Key features:

* **Multisig governance** for sensitive operations (pause, emergency withdraw, root updates).
* **Merkle-based airdrop claim system** with reentrancy protection and proper CEI pattern.
* **Deposit/withdraw functionality** with `msg.sender` accounting.
* **Timelocked transactions** to enforce delayed execution and prevent single-owner abuse.
* **Reentrancy guard** across all state-changing interactions.

---

## Architecture

The codebase is organized into modular components, each responsible for a single concern:

### 1. **VaultStorage**

* Single source of truth for all state variables.
* Holds balances, multisig owners, transaction logs, Merkle claim data, timelock constants, and reentrancy guard status.
* Prevents storage collisions across modules.

### 2. **AccessControl**

* Provides shared modifiers and helper functions:

  * `onlyOwner` – restricts access to registered owners.
  * `onlyVaultItself` – enforces multisig pipeline execution.
  * `whenNotPaused` – blocks functions when vault is paused.
  * `nonReentrant` – prevents reentrancy attacks.
* Includes `_initAccessControl` for owner registration and guard initialization.

### 3. **MultiSigModule**

* Implements a three-step multisig pipeline:

  1. Submit a transaction.
  2. Owners confirm until threshold is reached.
  3. Timelock expires → transaction executable by anyone.
* Handles confirmation revocation and ensures execution only after timelock.
* Ensures all sensitive vault functions are executed via multisig.

### 4. **MerkleClaimModule**

* Implements ETH claim system using Merkle proofs.
* Controlled via `onlyVaultItself` modifier to prevent unauthorized root updates.
* Uses CEI pattern and `.call{value: amount}` to safely transfer ETH.
* Tracks claimed addresses to prevent double-claims.

### 5. **EvictionVault (Main Contract)**

* Integrates `VaultStorage`, `AccessControl`, `MultiSigModule`, and `MerkleClaimModule`.
* Handles deposits, withdrawals, receive() ETH, pause/unpause, emergency withdrawals.
* Enforces all critical security measures:

  * Only vault can modify critical state.
  * Timelocked execution prevents immediate execution.
  * Reentrancy guard prevents recursive withdrawals.

---

## Project Structure

```
/EvictionVault
│
├─ /src
│   ├─ VaultStorage.sol
│   ├─ AccessControl.sol
│   ├─ modules/
│   │    ├─ MultiSigModule.sol
│   │    └─ MerkleClaimModule.sol
│   └─ EvictionVault.sol
│
├─ /test
│   └─ EvictionVault.t.sol
│
├─ forge.toml
└─ README.md
```

* `/src` – All contract source code, including modules.
* `/test` – Foundry-based tests validating deposit, withdraw, multisig, pause, emergency withdrawal, receive, and Merkle claim logic.
* `forge.toml` – Foundry configuration.

---

## Security Considerations

* **Critical Fixes Implemented**

  1. `setMerkleRoot` only callable via multisig.
  2. `emergencyWithdrawAll` gated by multisig.
  3. Pause/unpause restricted to multisig.
  4. `receive()` uses `msg.sender`, not `tx.origin`.
  5. `withdraw` and `claim` use `.call{value:...}` to avoid gas restrictions.
  6. Timelock execution cannot be bypassed by skipped confirmations.

* **Reentrancy Guard** – All external-facing ETH transfers protected.

* **CEI Pattern** – State updated before external interactions.

* **Timelock** – Enforces delayed execution for multisig transactions.

---

## Tests

* Written in Foundry (`forge-std/Test.sol`).

* Positive tests cover:

  1. Deposit accounting.
  2. Withdraw functionality with correct ETH return.
  3. Receive() credits correct sender.
  4. Multisig-only `setMerkleRoot`.
  5. Multisig-only `emergencyWithdrawAll`.
  6. Multisig-only `pause` and paused state enforcement.

* Tests ensure compliance with the hardened vault logic, including reentrancy protection and timelocked execution.

---

## Deployment & Usage

1. Deploy `EvictionVault` with initial owners and threshold.
2. Fund the vault as needed (ETH).
3. Sensitive actions (`pause`, `unpause`, `emergencyWithdrawAll`, `setMerkleRoot`) must go through the multisig pipeline:

   * Submit → Confirm by threshold → Execute after timelock.
4. Users can deposit ETH directly or via `deposit()`.
5. Users can claim ETH allocations using a valid Merkle proof through `claim()`.

---

## Recommendations for Developers

* Always verify Merkle roots and claims externally before deployment.
* Keep multisig owners’ keys secure.
* Monitor vault balance to ensure Merkle claims can be satisfied.
* Consider additional tests for multiple airdrops if extending Merkle claims.

---

This README presents a full overview of the contract system, the module architecture, security considerations, and developer guidance.

