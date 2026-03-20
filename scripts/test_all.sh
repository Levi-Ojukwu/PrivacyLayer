#!/usr/bin/env bash
# ============================================================
# PrivacyLayer — Run All Tests
# ============================================================
# Runs every test across the full stack:
#   1. Noir ZK circuit tests (nargo test)
#   2. Soroban contract unit tests (cargo test)
#   3. Soroban contract integration tests (cargo test integration)
#
# Usage:
#   chmod +x scripts/test_all.sh
#   ./scripts/test_all.sh
#
# Exit codes:
#   0 = all tests passed
#   1 = one or more test suites failed
# ============================================================

set -e  # Exit immediately on any failure

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

header() { echo -e "\n${YELLOW}══════════════════════════════${NC}"; echo -e "${YELLOW}  $1${NC}"; echo -e "${YELLOW}══════════════════════════════${NC}"; }
pass()   { echo -e "${GREEN}  ✅ $1${NC}"; PASS=$((PASS + 1)); }
fail()   { echo -e "${RED}  ❌ $1${NC}"; FAIL=$((FAIL + 1)); }

# ──────────────────────────────────────────────────────────────
# 1. Noir Circuit Tests
# ──────────────────────────────────────────────────────────────
header "Noir Circuit Tests (nargo test)"

cd "$ROOT_DIR/circuits"

for circuit in commitment merkle withdraw; do
    echo "  → Testing circuit: $circuit"
    if nargo test --package "$circuit" 2>&1; then
        pass "Circuit: $circuit — all tests passed"
    else
        fail "Circuit: $circuit — FAILED"
    fi
done

# ──────────────────────────────────────────────────────────────
# 2. Soroban Contract Unit Tests
# ──────────────────────────────────────────────────────────────
header "Soroban Contract Unit Tests (cargo test)"

cd "$ROOT_DIR/contracts"

if cargo test --package privacy_pool 2>&1; then
    pass "Soroban unit tests — all passed"
else
    fail "Soroban unit tests — FAILED"
fi

# ──────────────────────────────────────────────────────────────
# 3. Soroban Integration Tests
# ──────────────────────────────────────────────────────────────
header "Soroban Integration Tests (cargo test integration)"

cd "$ROOT_DIR/contracts"

if cargo test --package privacy_pool integration 2>&1; then
    pass "Soroban integration tests — all passed"
else
    fail "Soroban integration tests — FAILED"
fi

# ──────────────────────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════"
echo -e "  ${GREEN}PASSED: $PASS${NC}  ${RED}FAILED: $FAIL${NC}"
echo "══════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
echo ""
echo -e "${GREEN}All tests passed! 🎉${NC}"
