// ============================================================
// Address Decoder Utilities
// ============================================================
// Decodes addresses from 32-byte field elements in public inputs.
// ============================================================

use soroban_sdk::{Address, BytesN, Env};

/// Decode a Stellar address from a 32-byte field element.
///
/// The address is stored as a 32-byte hash in the ZK proof public inputs.
pub fn decode_address(env: &Env, address_bytes: &BytesN<32>) -> Address {
    let bytes_array: [u8; 32] = address_bytes.to_array();
    Address::from_string_bytes(&soroban_sdk::Bytes::from_slice(env, &bytes_array))
}

/// Decode an optional relayer address.
///
/// Returns `Some(Address)` if the relayer is non-zero, `None` otherwise.
pub fn decode_optional_relayer(env: &Env, relayer_bytes: &BytesN<32>) -> Option<Address> {
    let bytes_array: [u8; 32] = relayer_bytes.to_array();
    let zero = [0u8; 32];
    
    if bytes_array == zero {
        None
    } else {
        Some(Address::from_string_bytes(
            &soroban_sdk::Bytes::from_slice(env, &bytes_array)
        ))
    }
}
