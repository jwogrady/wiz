#!/usr/bin/env bash
# ==============================================================================
# Wiz Module: Bun JavaScript Runtime
# ==============================================================================
# Installs Bun, a fast all-in-one JavaScript runtime.
#
# Provides:
#   - Bun runtime
#   - Bun package manager
#   - Bun test runner
#   - Bun bundler
#
# Dependencies: essentials (for curl/wget)
#
# Usage:
#   ./install_bun.sh
#   or sourced by bootstrap orchestrator
#
# ==============================================================================

set -euo pipefail

# --- Module Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source module base
# shellcheck source=../module-base.sh
source "${SCRIPT_DIR}/../module-base.sh"

# Module metadata
MODULE_NAME="bun"
MODULE_VERSION="0.2.0"
MODULE_DESCRIPTION="Bun JavaScript runtime and package manager"
MODULE_DEPS="essentials"

# --- Module Interface Implementation ---

# describe_bun: Describe what this module will install
describe_bun() {
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🍞 BUN JAVASCRIPT RUNTIME
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This module installs Bun, a fast JavaScript runtime:

  ⚡ Fast Runtime:        All-in-one JavaScript runtime
  📦 Package Manager:     Fast npm/yarn/pnpm alternative
  🧪 Test Runner:         Built-in testing framework
  📦 Bundler:             Fast bundler for JavaScript/TypeScript
  🔧 Transpiler:          Built-in TypeScript/JSX support

Features:
  - Drop-in Node.js replacement
  - Faster than Node.js for many operations
  - Native bundler and test runner
  - Built-in TypeScript support

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# install_bun: Main installation logic
install_bun() {
    # Check if bun is already installed
    if check_command_installed bun; then
        module_skip "Already installed (use --force to reinstall)"
        return 0
    fi
    
    log "Installing Bun..."
    
    # Install via official installer
    progress "Downloading Bun installer..."
    
    # Download and run Bun installer (it's already non-interactive)
    if command_exists curl; then
        run "curl -fsSL https://bun.sh/install | bash" || {
            error "Bun installation via curl failed"
            module_fail "Bun installation failed"
        }
    elif command_exists wget; then
        run "wget -qO- https://bun.sh/install | bash" || {
            error "Bun installation via wget failed"
            module_fail "Bun installation failed"
        }
    else
        error "Neither curl nor wget available"
        module_fail "Bun installation failed"
    fi
    
    # Add Bun to PATH if installer added it to ~/.bun/bin
    add_to_path "$HOME/.bun/bin"
    
    # Verify installation
    if ! command_exists bun; then
        module_fail "Bun installation failed - command not found"
    fi
    
    local version
    version="$(get_command_version bun)"
    success "Bun installed: v${version}"
    
    return 0
}

# verify_bun: Verify installation succeeded
verify_bun() {
    log "Verifying Bun installation..."
    
    local failed=0
    
    # Ensure bun is in PATH
    add_to_path "$HOME/.bun/bin"
    
    # Check bun command exists
    if ! verify_command_exists bun; then
        ((failed++))
    fi
    
    # Test basic functionality
    if command_exists bun && bun --help >/dev/null 2>&1; then
        success "✓ bun command working"
    elif command_exists bun; then
        warn "bun --help failed"
    fi
    
    # Check installation directory
    if ! verify_file_or_dir "$HOME/.bun" "Bun directory" 1; then
        # Non-critical, just a warning
        :
    fi
    
    if [[ $failed -gt 0 ]]; then
        error "Verification failed with ${failed} error(s)"
        return 1
    fi
    
    success "Bun installation verified successfully"
    return 0
}

# --- Main Execution ---

# If script is executed directly (not sourced), run the module
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    execute_module "bun"
fi

