// ============================================================
// PrivacyLayer - Merkle Tree Tests
// ============================================================
// Test suite for the shared Merkle tree library.
// The actual implementation is in circuits/lib/merkle/mod.nr
// ============================================================

use lib::merkle;
use lib::hash;

// Re-export for external use
pub use lib::merkle::{compute_root, verify_inclusion, TREE_DEPTH};

// ============================================================
// Tests
// ============================================================

#[test]
fn test_single_leaf_tree() {
    // Depth-1 tree (simplified): just verify the hash composition
    let leaf: Field = 42;
    let sibling: Field = 0; // right sibling is zero (empty)
    let index: Field = 0;   // leaf is at position 0 (left)

    // For a single level, root = Hash(leaf, sibling)
    // But we have a 20-level tree - build a full path of zeros
    let mut hash_path: [Field; 20] = [0; 20];
    hash_path[0] = sibling;

    // Compute expected root by manually hashing up
    let mut expected = hash::hash_pair(leaf, sibling);
    for _i in 1..20 {
        expected = hash::hash_pair(expected, 0);
    }

    let computed = merkle::compute_root(leaf, index, hash_path);
    assert(computed == expected);
}

#[test]
fn test_right_child_position() {
    // Leaf at index=1 means it's the RIGHT child at level 0
    let leaf: Field = 99;
    let sibling: Field = 77;
    let index: Field = 1; // bit 0 = 1 - leaf is right child

    let mut hash_path: [Field; 20] = [0; 20];
    hash_path[0] = sibling;

    // At level 0: right child - hash(sibling, leaf)
    let mut expected = hash::hash_pair(sibling, leaf);
    for _i in 1..20 {
        expected = hash::hash_pair(expected, 0);
    }

    let computed = merkle::compute_root(leaf, index, hash_path);
    assert(computed == expected);
}

#[test]
fn test_same_leaf_same_root() {
    // Same inputs must always produce the same root (determinism)
    let leaf: Field = 12345;
    let index: Field = 7;
    let hash_path: [Field; 20] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];

    let root1 = merkle::compute_root(leaf, index, hash_path);
    let root2 = merkle::compute_root(leaf, index, hash_path);
    assert(root1 == root2);
}

#[test(should_fail_with = "merkle inclusion check failed: leaf not in tree")]
fn test_verify_inclusion_wrong_root_fails() {
    let leaf: Field = 42;
    let index: Field = 0;
    let hash_path: [Field; 20] = [0; 20];
    let wrong_root: Field = 9999; // not the real root

    merkle::verify_inclusion(leaf, index, hash_path, wrong_root);
}

#[test]
fn test_verify_inclusion_correct_root() {
    let leaf: Field = 42;
    let index: Field = 0;
    let hash_path: [Field; 20] = [0; 20];

    let correct_root = merkle::compute_root(leaf, index, hash_path);
    merkle::verify_inclusion(leaf, index, hash_path, correct_root); // should not panic
}

#[test(should_fail_with = "merkle inclusion check failed: leaf not in tree")]
fn test_verify_inclusion_wrong_index_fails() {
    let leaf: Field = 42;
    let hash_path: [Field; 20] = [0; 20];

    // Compute root for index=0, but verify with index=1 - different root
    let correct_root = merkle::compute_root(leaf, 0, hash_path);
    merkle::verify_inclusion(leaf, 1, hash_path, correct_root);
}
