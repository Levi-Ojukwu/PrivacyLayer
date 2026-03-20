// ============================================================
// Nullifier Storage
// ============================================================
// Manages nullifier spent status to prevent double-spends.
// ============================================================

use soroban_sdk::{BytesN, Env};

use crate::types::state::DataKey;

/// Check if a nullifier has been spent.
pub fn is_spent(env: &Env, nullifier_hash: &BytesN<32>) -> bool {
    let key = DataKey::Nullifier(nullifier_hash.clone());
    env.storage().persistent().has(&key)
}

/// Mark a nullifier as spent.
pub fn mark_spent(env: &Env, nullifier_hash: &BytesN<32>) {
    let key = DataKey::Nullifier(nullifier_hash.clone());
    env.storage().persistent().set(&key, &true);
}
