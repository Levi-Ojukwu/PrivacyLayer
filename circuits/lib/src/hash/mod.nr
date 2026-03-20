// ============================================================
// Hash Utilities
// ============================================================
// Centralized hash functions used across all circuits.
// Using Pedersen hash (BN254-friendly) as Poseidon is not yet
// in Noir 1.0 stdlib.
// ============================================================

use std::hash::pedersen_hash;

/// Compute commitment from nullifier and secret.
/// commitment = Hash(nullifier, secret)
pub fn compute_commitment(nullifier: Field, secret: Field) -> Field {
    pedersen_hash([nullifier, secret])
}

/// Compute nullifier hash bound to a specific root.
/// nullifier_hash = Hash(nullifier, root)
/// This prevents replay attacks across different pool states.
pub fn compute_nullifier_hash(nullifier: Field, root: Field) -> Field {
    pedersen_hash([nullifier, root])
}

/// Compute parent hash in Merkle tree.
/// parent = Hash(left, right)
pub fn hash_pair(left: Field, right: Field) -> Field {
    pedersen_hash([left, right])
}

/// Compute zero-value leaf hash.
/// Used to fill empty positions in the tree.
pub fn zero_leaf() -> Field {
    pedersen_hash([0, 0])
}
