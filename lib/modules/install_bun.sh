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
# Sourcing:
#   source /path/to/lib/module-base.sh   # then source this file
#
# ==============================================================================

set -euo pipefail

# --- Module Configuration ---
# shellcheck source=../module-base.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../module-base.sh"

# Module metadata
MODULE_NAME="bun"
MODULE_VERSION="0.2.0"
MODULE_DESCRIPTION="Bun JavaScript runtime and package manager"
MODULE_DEPS="essentials"

# --- Module Interface Implementation ---

# describe_bun: Describe what this module will install
describe_bun() {
    _module_banner "🍞 BUN JAVASCRIPT RUNTIME"
    cat << EOF

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

EOF
}

# install_bun: Main installation logic
install_bun() {
    # Check if bun is already installed
    if check_command_installed bun; then
        module_skip "Already installed (use --force to reinstall)"
        return 0
    fi
    
    # Resolve target version: CLI override or fetch latest
    local bun_target="${WIZ_BUN_VERSION:-latest}"
    log "Installing Bun ${bun_target}..."

    # Install via official installer
    progress "Downloading Bun installer..."

    # Download installer to temp file, then execute — avoids partial execution
    # on interrupted downloads. Bun does not publish a checksum for install.sh,
    # so we skip SHA verification and warn the user.
    local bun_tmp
    bun_tmp="$(download_to_temp "https://bun.sh/install" "Failed to download Bun installer")" || {
        module_fail "Bun installation failed"
    }

    warn "No published checksum for Bun installer — skipping SHA-256 verification"

    if [[ ${WIZ_DRY_RUN:-0} -eq 1 ]]; then
        log "[DRY-RUN] Would execute Bun installer: ${bun_tmp}"
        rm -f "$bun_tmp"
    else
        # Pass BUN_VERSION via env(1) so version string is never interpolated into
        # a shell command string — safe regardless of special characters in the value.
        if [[ "$bun_target" != "latest" ]]; then
            run_stream env BUN_VERSION="$bun_target" bash "$bun_tmp" || {
                rm -f "$bun_tmp"
                module_fail "Bun installation failed"
            }
        else
            run_stream bash "$bun_tmp" || {
                rm -f "$bun_tmp"
                module_fail "Bun installation failed"
            }
        fi
        rm -f "$bun_tmp"
    fi
    
    # Add Bun to PATH for current session
    add_to_path "$HOME/.bun/bin"
    
    # Ensure Bun is in shell configs (installer only adds to .bashrc)
    progress "Configuring Bun in shell profiles..."
    configure_bun_path
    
    # Verify installation
    if ! command_exists bun; then
        module_fail "Bun installation failed - command not found"
    fi
    
    local version
    version="$(get_command_version bun)"
    success "Bun installed: v${version}"
    
    return 0
}

# configure_bun_path: Add Bun to shell configuration files
configure_bun_path() {
    local bun_config
    read -r -d '' bun_config << 'EOF' || true
# >>> Bun init >>>
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# <<< Bun init <<<
EOF

    if [[ ${WIZ_DRY_RUN:-0} -eq 1 ]]; then
        log "[DRY-RUN] Would append Bun init block to shell profiles"
        return 0
    fi

    # Add to .zshrc if it exists
    if [[ -f "$HOME/.zshrc" ]]; then
        append_to_file_once "$HOME/.zshrc" ">>> Bun init >>>" "$bun_config"
        debug "Bun configuration present in .zshrc"
    fi

    # Add to .bashrc if it exists
    # (Bun installer may have already added it in its own format; normalize to ours)
    if [[ -f "$HOME/.bashrc" ]]; then
        # Remove old Bun installer format if present
        if grep -q "BUN_INSTALL" "$HOME/.bashrc" && \
           ! grep -q ">>> Bun init >>>" "$HOME/.bashrc"; then
            sed_inplace \
                '/^# bun$/d; /^export BUN_INSTALL=/d; /^export PATH=.*BUN_INSTALL/d' \
                "$HOME/.bashrc"
            debug "Removed old Bun configuration from .bashrc"
        fi
        append_to_file_once "$HOME/.bashrc" ">>> Bun init >>>" "$bun_config"
        debug "Bun configuration present in .bashrc"
    fi

    success "Bun PATH configured in shell profiles"
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

