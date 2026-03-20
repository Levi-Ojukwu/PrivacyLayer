// ============================================================
// Admin Functions - Pool management
// ============================================================

use soroban_sdk::{Address, Env};

use crate::storage::config;
use crate::types::errors::Error;
use crate::types::events::{emit_pool_paused, emit_pool_unpaused, emit_vk_updated};
use crate::types::state::VerifyingKey;
use crate::utils::validation;

/// Pause the pool - blocks deposits and withdrawals.
/// Only callable by admin.
pub fn pause(env: Env, admin: Address) -> Result<(), Error> {
    admin.require_auth();
    
    let mut pool_config = config::load(&env)?;
    validation::require_admin(&admin, &pool_config)?;

    pool_config.paused = true;
    config::save(&env, &pool_config);
    
    emit_pool_paused(&env, admin);
    Ok(())
}

/// Unpause the pool.
/// Only callable by admin.
pub fn unpause(env: Env, admin: Address) -> Result<(), Error> {
    admin.require_auth();
    
    let mut pool_config = config::load(&env)?;
    validation::require_admin(&admin, &pool_config)?;

    pool_config.paused = false;
    config::save(&env, &pool_config);
    
    emit_pool_unpaused(&env, admin);
    Ok(())
}

/// Update the Groth16 verifying key.
/// Only callable by admin. Critical operation - used for circuit upgrades.
pub fn set_verifying_key(
    env: Env,
    admin: Address,
    new_vk: VerifyingKey,
) -> Result<(), Error> {
    admin.require_auth();
    
    let pool_config = config::load(&env)?;
    validation::require_admin(&admin, &pool_config)?;

    config::save_verifying_key(&env, &new_vk);
    
    emit_vk_updated(&env, admin);
    Ok(())
}
