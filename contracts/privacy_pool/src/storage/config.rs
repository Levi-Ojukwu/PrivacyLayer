// ============================================================
// Configuration Storage
// ============================================================
// Manages pool configuration and verifying key storage.
// ============================================================

use soroban_sdk::Env;

use crate::types::errors::Error;
use crate::types::state::{DataKey, PoolConfig, VerifyingKey};

/// Check if the pool has been initialized.
pub fn exists(env: &Env) -> bool {
    env.storage().persistent().has(&DataKey::Config)
}

/// Load the pool configuration.
///
/// # Errors
/// Returns `Error::NotInitialized` if config doesn't exist.
pub fn load(env: &Env) -> Result<PoolConfig, Error> {
    env.storage()
        .persistent()
        .get(&DataKey::Config)
        .ok_or(Error::NotInitialized)
}

/// Save the pool configuration.
pub fn save(env: &Env, config: &PoolConfig) {
    env.storage().persistent().set(&DataKey::Config, config);
}

/// Load the verifying key.
///
/// # Errors
/// Returns `Error::NoVerifyingKey` if VK doesn't exist.
pub fn load_verifying_key(env: &Env) -> Result<VerifyingKey, Error> {
    env.storage()
        .persistent()
        .get(&DataKey::VerifyingKey)
        .ok_or(Error::NoVerifyingKey)
}

/// Save the verifying key.
pub fn save_verifying_key(env: &Env, vk: &VerifyingKey) {
    env.storage().persistent().set(&DataKey::VerifyingKey, vk);
}
