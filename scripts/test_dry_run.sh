#!/usr/bin/env bash
# ==============================================================================
# Wiz - Dry-Run Smoke Test
# ==============================================================================
# Simple smoke test to verify the installer works correctly in dry-run mode.
# This test validates:
#   - Installer can be executed with --dry-run flag
#   - No actual system changes are made
#   - Exit code is 0 (success)
#   - Output contains expected dry-run indicators
#
# Usage:
#   ./scripts/test_dry_run.sh
#
# Exit codes:
#   0 - Test passed
#   1 - Test failed
# ==============================================================================

set -euo pipefail

# Colors for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Test configuration
readonly INSTALLER="./bin/install"
readonly TEST_TIMEOUT=30

# Test counters
tests_run=0
tests_passed=0
tests_failed=0

# Helper functions
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

# Test: Installer exists and is executable
test_installer_exists() {
    info "Test 1: Checking installer exists and is executable"

    if [[ ! -f "${INSTALLER}" ]]; then
        fail "Installer not found: ${INSTALLER}"
        return 1
    fi

    if [[ ! -x "${INSTALLER}" ]]; then
        fail "Installer is not executable: ${INSTALLER}"
        return 1
    fi

    pass "Installer exists and is executable"
    return 0
}

# Test: Dry-run mode executes without errors
test_dry_run_execution() {
    info "Test 2: Testing dry-run mode execution"

    local output
    local exit_code=0

    # Run installer in dry-run mode with a timeout
    # Use --skip-identity to avoid interactive prompts
    output=$(timeout "${TEST_TIMEOUT}" "${INSTALLER}" \
        --dry-run --skip-identity 2>&1) || exit_code=$?

    # Check exit code
    if [[ ${exit_code} -eq 124 ]]; then
        fail "Installer timed out after ${TEST_TIMEOUT}s"
        return 1
    elif [[ ${exit_code} -ne 0 ]]; then
        fail "Installer exited with non-zero code: ${exit_code}"
        echo "${output}" | tail -20
        return 1
    fi

    # Check for dry-run indicators
    if echo "${output}" | grep -qi "dry-run\|DRY-RUN"; then
        pass "Dry-run mode executed successfully with expected output"
        return 0
    else
        fail "Dry-run mode executed but output doesn't contain expected \
indicators"
        echo "${output}" | head -30
        return 1
    fi
}

# Test: No actual changes made (verify critical files unchanged)
test_no_changes() {
    info "Test 3: Verifying no system changes made"

    # Create temporary state to track
    local test_state_dir="${HOME}/.wiz_test_state_$$"
    mkdir -p "${test_state_dir}"

    # Capture initial state (just check a few key files)
    local git_config_before
    local ssh_keys_before

    git_config_before=$(git config --global user.name 2>/dev/null || echo "")
    ssh_keys_before=$(ls -A "${HOME}/.ssh" 2>/dev/null | wc -l || echo "0")

    # Run dry-run
    "${INSTALLER}" --dry-run --skip-identity >/dev/null 2>&1 || true

    # Verify state unchanged
    local git_config_after
    local ssh_keys_after

    git_config_after=$(git config --global user.name 2>/dev/null || echo "")
    ssh_keys_after=$(ls -A "${HOME}/.ssh" 2>/dev/null | wc -l || echo "0")

    # Cleanup
    rm -rf "${test_state_dir}"

    if [[ "${git_config_before}" == "${git_config_after}" ]] && \
        [[ "${ssh_keys_before}" == "${ssh_keys_after}" ]]; then
        pass "No system changes detected (dry-run successful)"
        return 0
    else
        fail "System state changed during dry-run (should not happen)"
        return 1
    fi
}

# Test: Help message works
test_help() {
    info "Test 4: Testing --help flag"

    local output
    local exit_code=0

    output=$("${INSTALLER}" --help 2>&1) || exit_code=$?

    if [[ ${exit_code} -ne 0 ]]; then
        fail "Help command exited with non-zero code: ${exit_code}"
        return 1
    fi

    if echo "${output}" | grep -qi "usage\|help\|options"; then
        pass "Help message displays correctly"
        return 0
    else
        fail "Help message doesn't contain expected content"
        return 1
    fi
}

# Main test execution
main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Wiz Dry-Run Smoke Test"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Run all tests
    test_installer_exists
    test_help
    test_dry_run_execution
    test_no_changes

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
        return 0
    else
        echo -e "${RED}✖ Some tests failed${NC}"
        echo ""
        return 1
    fi
}

# Execute main function
main "$@"

