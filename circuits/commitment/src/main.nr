// ============================================================
// PrivacyLayer - Commitment Circuit
// ============================================================
// Proves knowledge of (nullifier, secret) such that:
//   commitment = Hash(nullifier, secret)
//
// This is the simplest building block - used during deposit.
// The commitment is stored publicly in the on-chain Merkle tree.
// The nullifier and secret are kept private by the user.
//
// Inspired by:
//   - Tornado Cash commitment scheme
//   - Penumbra note commitment (protocol.penumbra.zone)
// ============================================================

use lib::hash;
use lib::validation;

/// Commitment circuit - proves knowledge of a note's preimage.
///
/// # Private inputs
/// - `nullifier`  : unique per-note random field element; revealed on spend
/// - `secret`     : random field element; never revealed
///
/// # Public inputs
/// - `commitment` : Hash(nullifier, secret) - stored on-chain
fn main(
    // Private witnesses
    nullifier: Field,
    secret: Field,
    // Public statement
    commitment: pub Field,
) {
    // Compute commitment from private inputs
    let computed_commitment = hash::compute_commitment(nullifier, secret);

    // Validate the computed commitment matches the public on-chain value
    validation::validate_commitment(computed_commitment, commitment);
}

// ============================================================
// Tests - following noir-lang/noir-examples test patterns
// ============================================================

#[test]
fn test_valid_commitment() {
    // Known values: commitment = Hash(nullifier=1, secret=2)
    let nullifier: Field = 1;
    let secret: Field = 2;
    let commitment = hash::compute_commitment(nullifier, secret);

    // Should pass - correct preimage
    main(nullifier, secret, commitment);
}

#[test]
fn test_valid_commitment_large_values() {
    // Test with large field elements (near BN254 field prime)
    let nullifier: Field = 0x0000000000000000000000000000000000000000000000000000000000000064; // 100
    let secret: Field = 0x00000000000000000000000000000000000000000000000000000000000003e8; // 1000
    let commitment = hash::compute_commitment(nullifier, secret);

    main(nullifier, secret, commitment);
}

#[test(should_fail_with = "commitment mismatch: invalid nullifier/secret pair")]
fn test_wrong_nullifier_fails() {
    let nullifier: Field = 1;
    let secret: Field = 2;
    let commitment = hash::compute_commitment(nullifier, secret);

    // Provide wrong nullifier - should fail the assertion
    main(999, secret, commitment);
}

#[test(should_fail_with = "commitment mismatch: invalid nullifier/secret pair")]
fn test_wrong_secret_fails() {
    let nullifier: Field = 1;
    let secret: Field = 2;
    let commitment = hash::compute_commitment(nullifier, secret);

    // Provide wrong secret - should fail the assertion
    main(nullifier, 888, commitment);
}

#[test(should_fail_with = "commitment mismatch: invalid nullifier/secret pair")]
fn test_swapped_inputs_fails() {
    let nullifier: Field = 1;
    let secret: Field = 2;
    let commitment = hash::compute_commitment(nullifier, secret);

    // Swap nullifier and secret - should fail (hash is not symmetric)
    main(secret, nullifier, commitment);
}

#[test(should_fail_with = "commitment mismatch: invalid nullifier/secret pair")]
fn test_zero_inputs_with_wrong_commitment() {
    // Both zero with fabricated commitment value - should fail
    main(0, 0, 12345);
}

#[test]
fn test_zero_inputs_valid_commitment() {
    // Zero inputs should still work if commitment is correct
    let nullifier: Field = 0;
    let secret: Field = 0;
    let commitment = hash::compute_commitment(nullifier, secret);
    main(nullifier, secret, commitment);
}
