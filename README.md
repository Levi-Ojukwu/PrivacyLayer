# 🔐 PrivacyLayer

> **The first ZK-proof shielded pool on Stellar Soroban** — powered by Protocol 25's native BN254 and Poseidon cryptographic primitives.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Stellar Protocol 25](https://img.shields.io/badge/Stellar-Protocol%2025-blue)](https://stellar.org)
[![Built with Noir](https://img.shields.io/badge/ZK-Noir-black)](https://noir-lang.org)
[![Soroban](https://img.shields.io/badge/Smart%20Contracts-Soroban-purple)](https://soroban.stellar.org)

## Overview

PrivacyLayer enables **compliance-forward private transactions** on Stellar. Users deposit fixed-denomination XLM or USDC into a shielded pool, then withdraw to any address using a zero-knowledge proof — with no on-chain link between deposit and withdrawal.

Inspired by [Penumbra](https://github.com/penumbra-zone/penumbra) (Cosmos) and [Aztec Network](https://github.com/AztecProtocol/aztec-packages) (Ethereum), adapted natively for the Stellar/Soroban ecosystem.

### Why Now?

Stellar Protocol 25 (X-Ray, January 2026) added:
- ✅ **BN254 elliptic curve** operations (`G1`/`G2` add, scalar mul, pairing)
- ✅ **Poseidon / Poseidon2** hash functions
- ✅ Both are native Soroban host functions — no external libraries needed

No Soroban dApp has used these yet. PrivacyLayer is the first.

---

## Architecture

```
User                   PrivacyLayer SDK               Soroban Contract
 │                          │                               │
 │── deposit(amount) ──────►│                               │
 │                          │── generateNote() ────────────►│
 │                          │   (nullifier, secret)         │
 │                          │── Poseidon(nullifier,secret)  │
 │                          │   = commitment               │
 │                          │── deposit(commitment) ───────►│
 │                          │                    insert into│
 │◄── noteBackup ───────────│                    MerkleTree │
 │                          │                               │
 │── withdraw(note) ────────►│                               │
 │                          │── syncMerkleTree() ──────────►│
 │                          │◄── leaves[] ─────────────────│
 │                          │── generateMerkleProof()       │
 │                          │── generateZKProof() [WASM]    │
 │                          │   Groth16 via Noir prover     │
 │                          │── withdraw(proof) ───────────►│
 │                          │                    verifyG16  │
 │                          │                    BN254 pair │
 │◄── funds at new addr ────│◄── transfer() ───────────────│
```

### Core Cryptographic Flow

| Step | Operation | Protocol 25 Primitive |
|------|-----------|----------------------|
| Deposit | `commitment = Poseidon(nullifier ∥ secret)` | `poseidon2_hash` host fn |
| Store | Insert commitment into on-chain Merkle tree | Soroban storage |
| Withdraw (prove) | ZK proof: know preimage of a commitment in the tree | Noir circuit (BN254) |
| Withdraw (verify) | Groth16 pairing check on-chain | `bn254_pairing` host fn |

---

## Repository Structure

```
PrivacyLayer/
├── circuits/              # ZK circuits written in Noir
│   ├── commitment/        # Commitment scheme (Poseidon)
│   ├── withdraw/          # Withdrawal proof (Merkle + nullifier)
│   └── merkle/            # Shared Merkle utilities
├── contracts/             # Soroban smart contracts (Rust)
│   └── privacy_pool/
│       └── src/
│           ├── lib.rs     # Main contract (deposit, withdraw)
│           ├── merkle.rs  # Incremental Merkle tree (depth=20)
│           ├── verifier.rs# Groth16 verifier via BN254 host fns
│           ├── state.rs   # Contract state types
│           ├── events.rs  # Contract events
│           ├── errors.rs  # Error types
│           └── test.rs    # Integration tests
├── sdk/                   # TypeScript client SDK
│   └── src/
│       ├── note.ts        # Note generation
│       ├── deposit.ts     # Deposit flow
│       ├── withdraw.ts    # Withdraw flow (proof generation)
│       ├── merkle.ts      # Client-side Merkle sync
│       └── __tests__/     # Jest tests
├── frontend/              # Next.js dApp (Freighter wallet)
├── scripts/               # Deploy + key setup
├── docs/
│   ├── architecture.md
│   ├── protocol-spec.md
│   └── threat-model.md
├── FOUNDATION.md          # Project spec and roadmap
├── ISSUES.md              # Full 100-issue list for Drips Wave
└── CONTRIBUTING.md
```

---

## Getting Started

### Prerequisites

```bash
# Rust (for Soroban contracts)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add wasm32-unknown-unknown

# Stellar CLI
cargo install --locked stellar-cli

# Noir toolchain (nargo)
curl -L https://raw.githubusercontent.com/noir-lang/noirup/refs/heads/main/install | bash
noirup

# Node.js 18+ (for SDK and frontend)
# Use nvm: https://github.com/nvm-sh/nvm
```

### Build Circuits

```bash
cd circuits
nargo build       # Compile all circuits
nargo test        # Run circuit tests
```

### Build Contracts

```bash
cd contracts
cargo build --target wasm32-unknown-unknown --release
cargo test        # Run unit tests
```

### Build SDK

```bash
cd sdk
npm install
npm run build
npm test          # Run Jest tests
```

### Deploy to Testnet

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh --network testnet
```

---

## Security

> **⚠️ AUDIT STATUS: Unaudited. Do not use in production.**

This project uses zero-knowledge cryptography. While the mathematical primitives (BN254, Poseidon) are battle-tested, the circuit logic and contract integration require a formal security audit before mainnet deployment.

See [`docs/threat-model.md`](docs/threat-model.md) for known risks.

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). This project is funded via [Drips Wave](https://www.drips.network/wave) — contributors earn USDC for completing issues.

---

## License

MIT — see [`LICENSE`](LICENSE)

---

## References

- [Stellar Protocol 25 (X-Ray) Blog Post](https://stellar.org/blog/developers/protocol-25-x-ray)
- [CAP-0074: BN254 Host Functions](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0074.md)
- [CAP-0075: Poseidon Hash](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0075.md)
- [Penumbra Shielded Pool](https://protocol.penumbra.zone/main/shielded-pool.html)
- [How Tornado Cash Works](https://tornado-cash.medium.com/tornado-cash-how-it-works-1c9c87c06769)
- [Noir Language Docs](https://noir-lang.org/docs)
- [Soroban SDK Docs](https://docs.rs/soroban-sdk)
