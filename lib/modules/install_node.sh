#!/usr/bin/env bash
# ==============================================================================
# Wiz Module: Node.js via NVM
# ==============================================================================
# Installs NVM (Node Version Manager) and Node.js LTS with proper shell
# integration for both Bash and Zsh.
#
# Provides:
#   - NVM (Node Version Manager)
#   - Node.js LTS version
#   - npm package manager
#   - Corepack (for Yarn/pnpm)
#
# Dependencies: essentials (for curl, wget, build-essential)
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
MODULE_NAME="node"
MODULE_VERSION="0.2.0"
MODULE_DESCRIPTION="Node.js LTS via NVM with shell integration"
MODULE_DEPS="essentials"

# Configuration
NVM_VERSION="v0.39.7"
NVM_DIR="${HOME}/.nvm"
# SHA-256 of the NVM install.sh for NVM_VERSION above.
# Must be set — installation aborts if empty (fail-closed security posture).
# To obtain: curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | sha256sum
# Update this constant whenever NVM_VERSION is bumped.
NVM_INSTALLER_SHA256="8e45fa547f428e9196a5613efad3bfa4d4608b74ca870f930090598f5af5f643"

# Shell init block — identical content for both bash and zsh
_NVM_SHELL_BLOCK='
# >>> NVM init >>>
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
# <<< NVM init <<<'

# --- Module Interface Implementation ---

# describe_node: Describe what this module will install
describe_node() {
    local node_target="${WIZ_NODE_VERSION:-lts}"
    _module_banner "📦 NODE.JS VIA NVM"
    cat << EOF

This module installs Node.js development environment:

  📦 NVM ${NVM_VERSION}:     Node Version Manager
  🟢 Node.js ${node_target}:        Target version (override with --node-version)
  📋 npm:                Node package manager
  🔧 Corepack:           Yarn & pnpm package manager support

Shell Integration:
  - Bash (~/.bashrc)
  - Zsh (~/.zshrc)

Configuration:
  - Disables funding messages
  - Disables audit by default
  - Sets moderate audit level
  - Minimal npm output

EOF
}

# install_node: Main installation logic
install_node() {
    log "Installing NVM and Node.js LTS..."

    # Install NVM if not present
    if [[ ! -d "$NVM_DIR" ]]; then
        log "Installing NVM ${NVM_VERSION}..."

        # Fail-closed: NVM_INSTALLER_SHA256 must be set before downloading.
        # Check here so we avoid downloading a file we would immediately discard.
        if [[ -z "$NVM_INSTALLER_SHA256" ]]; then
            module_fail "NVM_INSTALLER_SHA256 is not set. To obtain the value, run: curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | sha256sum"
        fi

        local nvm_tmp
        nvm_tmp="$(wiz_download_verified \
            "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" \
            "$NVM_INSTALLER_SHA256" \
            "Failed to download NVM installer")" || module_fail "NVM installation failed"

        if [[ ${WIZ_DRY_RUN:-0} -eq 1 ]]; then
            log "[DRY-RUN] Would execute NVM installer: ${nvm_tmp}"
            rm -f "$nvm_tmp"
        else
            run_shell "bash '$nvm_tmp'" || {
                rm -f "$nvm_tmp"
                module_fail "NVM installation failed"
            }
            rm -f "$nvm_tmp"
        fi

        success "NVM installed successfully"
    else
        log "NVM already installed at ${NVM_DIR}"
    fi

    # Load NVM into current shell
    export NVM_DIR
    # Temporarily disable nounset for NVM loading
    set +u
    # shellcheck source=/dev/null
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    # shellcheck source=/dev/null
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    set -u

    # Verify NVM loaded
    if ! command_exists nvm; then
        module_fail "NVM failed to load after installation"
    fi

    # Add NVM init to ~/.bashrc and ~/.zshrc (idempotent)
    log "Configuring shell integration..."
    wiz_add_shell_block ">>> NVM init >>>" "$_NVM_SHELL_BLOCK"

    # Resolve target version: CLI override or fall back to LTS
    local node_target="${WIZ_NODE_VERSION:-lts}"
    local nvm_install_arg
    local nvm_use_arg
    if [[ "$node_target" == "lts" ]]; then
        nvm_install_arg="--lts"
        nvm_use_arg="--lts"
    else
        nvm_install_arg="$node_target"
        nvm_use_arg="$node_target"
    fi

    # Install or update Node
    # NOTE: nvm is a shell function, so we must use run_shell
    if ! command_exists node; then
        log "Installing Node.js ${node_target}..."
        set +u
        run_shell "nvm install ${nvm_install_arg}" || {
            set -u
            module_fail "Failed to install Node.js ${node_target}"
        }
        set -u
    else
        log "Updating to Node.js ${node_target}..."
        set +u
        run_shell "nvm install ${nvm_install_arg}" || \
            warn "Node.js ${node_target} update had issues, continuing..."
        if [[ "$node_target" == "lts" ]]; then
            run_shell "nvm alias default 'lts/*'" || warn "Failed to set default alias"
        else
            run_shell "nvm alias default '${node_target}'" || warn "Failed to set default alias"
        fi
        set -u
    fi

    # Use target version
    set +u
    run_shell "nvm use ${nvm_use_arg}" || {
        set -u
        module_fail "Failed to switch to Node.js ${node_target}"
    }
    set -u

    # Ensure node/npm are on PATH in the current shell.
    # NVM commands above run in subshells (via run_shell), so their PATH
    # changes are lost. Re-source NVM to pick up the installed node.
    set +u
    export NVM_DIR="${HOME}/.nvm"
    # shellcheck source=/dev/null
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    set -u
    add_to_path "${HOME}/.nvm/versions/node/$(node -v 2>/dev/null || echo v0)/bin" 2>/dev/null || true

    # Configure npm
    log "Configuring npm..."
    run npm config set fund false || warn "Failed to disable funding messages"
    run npm config set audit false || warn "Failed to disable audit"
    run npm config set audit-level moderate || warn "Failed to set audit level"
    run npm config set loglevel warn || warn "Failed to set log level"

    # Enable Corepack for Yarn & pnpm
    if command_exists corepack; then
        log "Enabling Corepack..."
        run corepack enable || warn "Failed to enable Corepack"
    fi

    # Display versions
    local node_version
    local npm_version
    node_version="$(node -v 2>/dev/null || echo 'unknown')"
    npm_version="$(npm -v 2>/dev/null || echo 'unknown')"

    success "Node.js ${node_version} installed"
    success "npm ${npm_version} configured"

    return 0
}

# verify_node: Verify installation succeeded
verify_node() {
    local failed=0

    log "Verifying Node.js installation..."

    # Check NVM directory exists
    if [[ ! -d "$NVM_DIR" ]]; then
        error "NVM directory not found: ${NVM_DIR}"
        ((failed++)) || true
    fi

    # Load NVM for verification
    export NVM_DIR
    set +u
    # shellcheck source=/dev/null
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    set -u

    # Verify NVM command (nvm is a shell function, so check differently)
    if ! command_exists nvm && ! declare -f nvm >/dev/null 2>&1; then
        error "nvm command not available"
        ((failed++)) || true
    else
        success "✓ nvm command available"
    fi

    # Verify Node.js
    if ! verify_command_exists node; then
        ((failed++)) || true
    fi

    # Verify npm
    if ! verify_command_exists npm; then
        ((failed++)) || true
    fi

    # Check shell RC files have NVM init
    for rc_file in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
        if [[ -f "$rc_file" ]]; then
            if grep -q '# >>> NVM init >>>' "$rc_file"; then
                success "✓ NVM init present in ${rc_file}"
            else
                warn "NVM init missing from ${rc_file}"
            fi
        fi
    done

    if [[ $failed -gt 0 ]]; then
        error "Verification failed with ${failed} error(s)"
        return 1
    fi

    success "Node.js installation verified successfully"
    return 0
}

# --- Main Execution ---

# If script is executed directly (not sourced), run the module
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    execute_module "node"
fi
