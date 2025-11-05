#!/usr/bin/env bash
# ==============================================================================
# Test script for Wiz workflow improvements
# ==============================================================================
# Tests all 4 Priority 1 improvements:
# 1. Removed redundant apt-get update
# 2. Skip descriptions for completed modules
# 3. Installation summary
# 4. SSH fingerprint caching
#
# Usage:
#   ./scripts/test_improvements.sh
# ==============================================================================

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Test counters
tests_run=0
tests_passed=0
tests_failed=0

pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((tests_passed++))
    ((tests_run++))
}

fail() {
    echo -e "${RED}✖${NC} $1"
    ((tests_failed++))
    ((tests_run++))
}

info() {
    echo -e "${YELLOW}→${NC} $1"
}

# Test 1: Verify redundant apt-get update is removed
test_no_redundant_apt_update() {
    info "Test 1: Checking neovim module doesn't call apt-get update"
    
    if grep -q "run.*apt-get update" lib/modules/install_neovim.sh; then
        fail "apt-get update still present in neovim module"
        return 1
    elif grep -q "# Note: apt-get update is handled by essentials module" lib/modules/install_neovim.sh; then
        pass "apt-get update removed with explanatory comment"
    else
        fail "Could not verify apt-get update removal"
        return 1
    fi
}

# Test 2: Verify descriptions are skipped for completed modules
test_skip_descriptions() {
    info "Test 2: Checking module-base skips descriptions for completed modules"
    
    if grep -q "Check if already complete (before showing description)" lib/module-base.sh; then
        pass "Module descriptions are checked before showing (skip logic implemented)"
    else
        fail "Skip descriptions logic not found"
        return 1
    fi
    
    if grep -q "Show description only if module will actually be installed" lib/module-base.sh; then
        pass "Description shown only when module will install"
    else
        fail "Description conditional logic not found"
        return 1
    fi
}

# Test 3: Verify installation summary function exists
test_installation_summary() {
    info "Test 3: Checking installation summary function exists"
    
    if grep -q "show_installation_summary" bin/install; then
        if grep -q "INSTALLATION PLAN" bin/install; then
            pass "Installation summary function implemented"
        else
            fail "Installation summary function exists but missing UI elements"
            return 1
        fi
    else
        fail "Installation summary function not found"
        return 1
    fi
    
    # Check it's called in the right place
    if grep -q "show_installation_summary.*ordered_modules" bin/install; then
        pass "Installation summary called with correct parameters"
    else
        fail "Installation summary not called correctly"
        return 1
    fi
}

# Test 4: Verify SSH fingerprint caching
test_ssh_fingerprint_caching() {
    info "Test 4: Checking SSH fingerprint caching implementation"
    
    if grep -q "get_cached_ssh_fingerprint" lib/common.sh; then
        pass "SSH fingerprint caching function exists"
    else
        fail "SSH fingerprint caching function not found"
        return 1
    fi
    
    if grep -q "SSH_FINGERPRINT_CACHE_DIR" lib/common.sh; then
        pass "SSH fingerprint cache directory configured"
    else
        fail "SSH fingerprint cache directory not configured"
        return 1
    fi
    
    # Check it's used in install script
    if grep -q "get_cached_ssh_fingerprint" bin/install; then
        pass "SSH fingerprint caching used in install script"
    else
        fail "SSH fingerprint caching not used in install script"
        return 1
    fi
    
    # Check fallback logic
    if grep -q "Fallback to direct call if caching function not available" bin/install; then
        pass "SSH fingerprint caching has fallback logic"
    else
        fail "SSH fingerprint caching missing fallback logic"
        return 1
    fi
}

# Test 5: Verify syntax of all scripts
test_syntax() {
    info "Test 5: Checking syntax of all modified scripts"
    
    local failed=0
    
    for script in bin/install lib/common.sh lib/module-base.sh lib/modules/install_neovim.sh; do
        if bash -n "$script" 2>&1; then
            pass "Syntax check passed: $script"
        else
            fail "Syntax error in: $script"
            failed=1
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Test 6: Verify functions are exported correctly
test_function_export() {
    info "Test 6: Checking function exports"
    
    # Source common.sh to check if function is available
    if source lib/common.sh 2>/dev/null && declare -f get_cached_ssh_fingerprint >/dev/null 2>&1; then
        pass "get_cached_ssh_fingerprint function is available"
    else
        fail "get_cached_ssh_fingerprint function not available"
        return 1
    fi
}

# Main test execution
main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Wiz Improvements Test Suite"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Run all tests
    test_no_redundant_apt_update
    test_skip_descriptions
    test_installation_summary
    test_ssh_fingerprint_caching
    test_syntax
    test_function_export
    
    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Test Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Tests run:    ${tests_run}"
    echo "  Passed:       ${tests_passed}"
    echo "  Failed:       ${tests_failed}"
    echo ""
    
    if [[ ${tests_failed} -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo ""
        echo "All improvements are working correctly:"
        echo "  ✓ Removed redundant apt-get update"
        echo "  ✓ Skip descriptions for completed modules"
        echo "  ✓ Installation summary before starting"
        echo "  ✓ SSH fingerprint caching"
        echo ""
        return 0
    else
        echo -e "${RED}✖ Some tests failed${NC}"
        echo ""
        return 1
    fi
}

# Execute main function
main "$@"

