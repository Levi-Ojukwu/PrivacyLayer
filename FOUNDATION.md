# 🔐 PrivacyLayer — Stellar ZK Shielded Pool

> **First ZK privacy dApp on Stellar Soroban — leveraging Protocol 25's native BN254 + Poseidon primitives.**
>
> Inspired by [Penumbra](https://github.com/penumbra-zone/penumbra) (Cosmos) and [Aztec Network](https://github.com/AztecProtocol/aztec-packages) (Ethereum), adapted for the Stellar ecosystem.

---

## 🧭 Project Overview

PrivacyLayer is a **compliance-forward, ZK-proof-based shielded pool** on Soroban.  
Users can deposit XLM/USDC, hold funds privately, and withdraw to any address — without linking deposit to withdrawal on-chain.

**Core mechanism** (borrowed from Tornado Cash / Penumbra):
1. **Deposit** → generate a secret `note`, compute a `commitment = Poseidon(nullifier, secret)`, store in on-chain Merkle tree
2. **Withdraw** → generate ZK proof proving you know a note in the tree, reveal nullifier, receive funds at any address — no link to depositor

**Protocol 25 advantage:**  
Stellar now has native `BN254` pairing support and `Poseidon` hash host functions — the exact primitives needed for Groth16 proof verification and ZK-friendly commitments. **No other Soroban dApp uses these yet.**

---

## 🏗️ Repository Structure

```
PrivacyLayer/
│
├── FOUNDATION.md              ← This document
│
├── circuits/                  ← ZK circuits (Noir)
│   ├── commitment/
│   │   └── src/main.nr        ← Commitment scheme circuit
│   ├── withdraw/
│   │   └── src/main.nr        ← Withdrawal proof circuit (main)
│   └── Nargo.toml
│
├── contracts/                 ← Soroban smart contracts (Rust)
│   ├── privacy_pool/
│   │   ├── src/
│   │   │   ├── lib.rs         ← Main contract entrypoint
│   │   │   ├── merkle.rs      ← Incremental Merkle tree
│   │   │   ├── verifier.rs    ← Groth16 proof verifier (BN254)
│   │   │   └── state.rs       ← Contract state definitions
│   │   └── Cargo.toml
│   └── Cargo.toml
│
├── sdk/                       ← TypeScript client SDK
│   ├── src/
│   │   ├── index.ts           ← Main exports
│   │   ├── deposit.ts         ← Deposit flow (generate note + submit)
│   │   ├── withdraw.ts        ← Withdraw flow (generate proof + submit)
│   │   ├── merkle.ts          ← Client-side Merkle tree sync
│   │   └── types.ts           ← Shared types
│   ├── package.json
│   └── tsconfig.json
│
├── frontend/                  ← React/Next.js dApp
│   ├── src/
│   │   ├── app/
│   │   ├── components/
│   │   └── hooks/
│   └── package.json
│
├── scripts/                   ← Deployment + setup scripts
│   ├── deploy.sh
│   └── setup_keys.sh          ← Proving/verifying key generation
│
└── docs/
    ├── architecture.md
    ├── protocol-spec.md
    └── threat-model.md
```

---

## 🔬 Phase 1 — Foundation (10-20% scope, this PR series)

> **Goal**: Prove end-to-end that ZK proofs can be verified inside a Soroban contract using Protocol 25 primitives.

### ✅ Milestone 1.1 — ZK Circuit: Commitment Scheme

**File**: `circuits/commitment/src/main.nr`

What it proves: *"I know a secret `s` and nullifier `n` such that `Poseidon(n, s) == commitment`"*

```noir
use dep::std::hash::poseidon;

fn main(
    // Private inputs (known only to the user)
    nullifier: Field,
    secret: Field,
    // Public input (stored on-chain)
    commitment: pub Field
) {
    let computed = poseidon::bn254::hash_2([nullifier, secret]);
    assert(computed == commitment);
}
```

**Why this matters**: This is the exact Poseidon flavor supported by Stellar Protocol 25's `poseidon_hash` host function. The commitment scheme is the atomic unit of all ZK privacy systems.

---

### ✅ Milestone 1.2 — Soroban Contract: Merkle Tree + Commitment Store

**File**: `contracts/privacy_pool/src/merkle.rs`

An **incremental Merkle tree** (depth = 20, supports ~1M notes) stored in Soroban's persistent storage.

Key interface:
```rust
pub fn insert_commitment(env: &Env, commitment: BytesN<32>) -> u32
pub fn get_root(env: &Env) -> BytesN<32>
pub fn is_known_root(env: &Env, root: BytesN<32>) -> bool
pub fn is_known_nullifier(env: &Env, nullifier: BytesN<32>) -> bool
```

**Inspired by**: [Tornado Cash's MerkleTreeWithHistory](https://github.com/tornadocash/tornado-core/blob/master/contracts/MerkleTreeWithHistory.sol) — battle-tested, ported to Rust/Soroban.

---

### ✅ Milestone 1.3 — Soroban Contract: Groth16 Verifier (BN254)

**File**: `contracts/privacy_pool/src/verifier.rs`

Uses Stellar Protocol 25's `bn254_g1_add`, `bn254_g1_mul`, `bn254_pairing` host functions to verify a Groth16 proof on-chain.

```rust
pub fn verify_groth16_proof(
    env: &Env,
    proof: Bytes,        // [A, B, C] points encoded
    public_inputs: Vec<BytesN<32>>,  // [root, nullifier_hash, recipient, amount]
) -> bool
```

**Key insight**: This is the first time these Protocol 25 host functions would be used in production on Stellar mainnet.

---

### ✅ Milestone 1.4 — Soroban Contract: Deposit Entrypoint

**File**: `contracts/privacy_pool/src/lib.rs`

```rust
pub fn deposit(
    env: Env,
    from: Address,
    commitment: BytesN<32>,
    amount: i128,         // Fixed denomination (e.g. 100 XLM)
) -> u32                  // Returns leaf index in Merkle tree
```

Flow:
1. Transfer `amount` XLM from `from` to contract vault
2. Insert `commitment` into Merkle tree
3. Emit `DepositEvent { commitment, leaf_index, timestamp }`
4. Return leaf index (user stores this client-side with their secret note)

---

### ✅ Milestone 1.5 — Soroban Contract: Withdraw Entrypoint

**File**: `contracts/privacy_pool/src/lib.rs`

```rust
pub fn withdraw(
    env: Env,
    proof: Bytes,
    root: BytesN<32>,
    nullifier_hash: BytesN<32>,
    recipient: Address,
    amount: i128,
    relayer: Option<Address>,
    fee: i128,
) -> bool
```

Flow:
1. Verify `root` is a known historical root
2. Verify `nullifier_hash` has not been used
3. Verify Groth16 proof with public inputs `[root, nullifier_hash, recipient, amount]`
4. Mark `nullifier_hash` as spent
5. Transfer `amount - fee` to `recipient`, `fee` to `relayer`

---

### ✅ Milestone 1.6 — TypeScript SDK: Deposit Flow

**File**: `sdk/src/deposit.ts`

```typescript
export interface Note {
  nullifier: bigint;
  secret: bigint;
  commitment: string;    // hex
  amount: bigint;
  denomination: string;  // "XLM" | "USDC"
}

export async function createNote(amount: bigint, denomination: string): Promise<Note>
export async function deposit(note: Note, keypair: Keypair): Promise<string> // txHash
export function serializeNote(note: Note): string   // encrypted backup string
export function deserializeNote(s: string): Note
```

Client-side proof generation using `@noir-lang/noir_js` (WASM compiled Noir prover).

---

### ✅ Milestone 1.7 — TypeScript SDK: Withdraw Flow

**File**: `sdk/src/withdraw.ts`

```typescript
export async function withdraw(
  note: Note,
  recipient: string,        // Stellar address
  relayer?: RelayerConfig,
): Promise<string>          // txHash
```

Flow:
1. Sync Merkle tree from on-chain events
2. Compute Merkle proof (inclusion proof) for note's commitment
3. Generate Groth16 proof via Noir WASM prover
4. Submit `withdraw` transaction to Soroban contract

---

## 🎯 GitHub Issues for Drips Wave

> These are the contribution units for the Drips Wave program. Each issue = one bounty.

| # | Title | Complexity | Phase |
|---|-------|------------|-------|
| 1 | `[Circuit]` Implement Poseidon commitment scheme in Noir | Medium | 1.1 |
| 2 | `[Circuit]` Implement withdrawal proof circuit (Merkle inclusion + nullifier) | Hard | 1.2 |
| 3 | `[Contract]` Incremental Merkle tree in Soroban (depth=20) | Hard | 1.2 |
| 4 | `[Contract]` Groth16 verifier using Protocol 25 BN254 host functions | Hard | 1.3 |
| 5 | `[Contract]` Deposit entrypoint + event emission | Medium | 1.4 |
| 6 | `[Contract]` Withdraw entrypoint + nullifier spend check | Medium | 1.5 |
| 7 | `[SDK]` Note generation + Poseidon commitment (TypeScript) | Medium | 1.6 |
| 8 | `[SDK]` Deposit flow — Freighter wallet integration | Medium | 1.6 |
| 9 | `[SDK]` Client-side Merkle tree sync from chain events | Hard | 1.7 |
| 10 | `[SDK]` Withdraw flow — Noir WASM proof generation | Hard | 1.7 |
| 11 | `[Tests]` End-to-end deposit → withdraw on testnet | Medium | All |
| 12 | `[Docs]` Protocol spec + threat model write-up | Easy | All |

---

## 📚 Reference Implementations to Study

| Source | What to borrow |
|--------|----------------|
| [Tornado Cash Core](https://github.com/tornadocash/tornado-core) | Merkle tree, commitment/nullifier scheme, circuit structure |
| [Penumbra shielded pool](https://github.com/penumbra-zone/penumbra/tree/main/crates/core/component/shielded-pool) | Multi-asset note design, spend authorization |
| [Aztec.nr](https://github.com/AztecProtocol/aztec-packages/tree/master/noir-projects/aztec-nr) | Noir circuit patterns, note interface |
| [noir-lang/noir-examples](https://github.com/noir-lang/noir-examples) | Merkle inclusion proofs, Groth16 output |
| [EkuboProtocol/privacy-pools](https://github.com/EkuboProtocol/privacy-pools) | Privacy pool with Circom circuits — port patterns to Noir |

---

## ⚠️ Design Decisions (Compliance-First)

Following SDF's guidance on Protocol 25 privacy:

1. **Fixed denominations only** (100 XLM, 1000 XLM) — prevents amount-based fingerprinting while remaining auditable
2. **No mixer, not a tumbler** — user retains their nullifier; can prove origin voluntarily (selective disclosure)
3. **Relayer network** — allows gasless withdrawals without linking sender/recipient wallets
4. **No sanctions bypass** — on-chain screener checks recipient against OFAC list pre-withdrawal

---

## 🛠️ Tech Stack Summary

| Layer | Language | Tool |
|-------|----------|------|
| ZK circuits | **Noir** | `nargo` CLI, Groth16 backend |
| On-chain contracts | **Rust** | `soroban-sdk`, Stellar CLI |
| Client SDK | **TypeScript** | `@noir-lang/noir_js`, `@stellar/stellar-sdk` |
| Frontend | **TypeScript** | Next.js, Freighter wallet |
| Proving setup | **Node.js** | `snarkjs` (trusted setup ceremony) |

---

## 🚀 Getting Started (Contributor Guide)

```bash
# Clone the repo
git clone https://github.com/YOUR_HANDLE/PrivacyLayer
cd PrivacyLayer

# Install Noir toolchain
curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
noirup

# Install Stellar CLI
cargo install --locked stellar-cli

# Build circuits
cd circuits && nargo build

# Build contracts
cd contracts && cargo build --target wasm32-unknown-unknown

# Install SDK deps
cd sdk && npm install
```

**Prerequisites**: Rust 1.74+, Node.js 18+, `nargo` (Noir CLI), Stellar CLI

---

*Built on Stellar Protocol 25 (X-Ray) — January 2026*  
*Inspired by Penumbra, Aztec, Tornado Cash — first-mover on Stellar*
