# Contributing to PrivacyLayer

> This project is funded via [Drips Wave](https://www.drips.network/wave) on the Stellar ecosystem. Contributors earn **USDC rewards** for completing GitHub issues.

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/YOUR_HANDLE/PrivacyLayer && cd PrivacyLayer

# 2. Install tools
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add wasm32-unknown-unknown
cargo install --locked stellar-cli
curl -L https://raw.githubusercontent.com/noir-lang/noirup/refs/heads/main/install | bash && noirup

# 3. Run ALL tests
chmod +x scripts/test_all.sh
./scripts/test_all.sh
```

---

## Running Tests

### Noir ZK Circuits

```bash
cd circuits

# All circuits at once
nargo test

# Single circuit verbose
nargo test --package commitment --show-output
nargo test --package merkle     --show-output
nargo test --package withdraw   --show-output
```

### Soroban Contracts (Rust)

```bash
cd contracts

# All tests (unit + integration)
cargo test

# Unit tests only
cargo test --package privacy_pool --lib

# Integration tests only
cargo test --package privacy_pool integration

# Single test by name
cargo test --package privacy_pool test_e2e_single_deposit_withdraw -- --nocapture

# With logs
RUST_LOG=debug cargo test --package privacy_pool -- --nocapture
```

### All tests at once

```bash
./scripts/test_all.sh
```

---

## Test Coverage Map

| Test File | Layer | # Tests | What It Covers |
|-----------|-------|---------|----------------|
| `circuits/commitment/src/main.nr` | Circuit | 7 | Poseidon2 commitment roundtrip, invalid inputs |
| `circuits/merkle/src/lib.nr` | Circuit | 6 | Merkle root computation, inclusion proofs |
| `circuits/withdraw/src/main.nr` | Circuit | 6 | Full withdrawal proof, all edge cases |
| `circuits/integration_test.nr` | Circuit E2E | 10 | Full SDK→circuit flow |
| `contracts/privacy_pool/src/test.rs` | Contract Unit | 20+ | Per-function unit tests |
| `contracts/privacy_pool/src/integration_test.rs` | Contract E2E | 14 | Full deposit→withdraw flows |

**Total**: ~63 tests across circuits and contracts.

---

## How to Pick an Issue

1. Browse [ISSUES.md](ISSUES.md) or the GitHub Issues tab
2. Check if the issue is unassigned
3. Comment `I'm working on this` — maintainer will assign it
4. Fork, branch, implement, write tests, open PR

### Branch Naming

```
feat/issue-42-bn254-scalar-mul
fix/issue-17-nullifier-double-spend
test/issue-65-sdk-withdraw-integration
docs/issue-88-threat-model
```

### PR Requirements

- [ ] All existing tests still pass (`./scripts/test_all.sh`)
- [ ] New tests added for new functionality
- [ ] Code follows the existing module structure
- [ ] `cargo clippy` passes (contracts)
- [ ] `nargo check` passes (circuits)
- [ ] PR description explains the change and references the issue

---

## Code Style

### Rust (Contracts)
- `rustfmt` for formatting: `cargo fmt`
- `clippy` for lints: `cargo clippy -- -D warnings`
- Every public function must have a doc comment explaining purpose, args, errors

### Noir (Circuits)
- Comments above every `fn main` explain private vs public inputs
- Every constraint has a comment explaining WHY it's needed
- `#[test(should_fail_with = "...")]` for negative tests — always include the exact panic message

---

## Architecture Primer

Before contributing, read:
1. [`FOUNDATION.md`](FOUNDATION.md) — project spec and full roadmap
2. [`contracts/privacy_pool/src/state.rs`](contracts/privacy_pool/src/state.rs) — data types
3. [`contracts/privacy_pool/src/lib.rs`](contracts/privacy_pool/src/lib.rs) — main entry points

Key invariants that must never be broken:
- `commitment` is never zero
- `nullifier_hash` is always stored after withdrawal
- `root` must always be checked against `ROOT_HISTORY_SIZE` circular buffer
- Proof verification happens BEFORE any state changes or token transfers

---

## Questions?

Open a [GitHub Discussion](https://github.com/YOUR_HANDLE/PrivacyLayer/discussions) or reach out on the Stellar Discord `#soroban` channel.
