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
# Usage:
#   ./install_node.sh
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
MODULE_NAME="node"
MODULE_VERSION="0.2.0"
MODULE_DESCRIPTION="Node.js LTS via NVM with shell integration"
MODULE_DEPS="essentials"

# Configuration
NVM_VERSION="v0.39.7"
NVM_DIR="${HOME}/.nvm"

# --- Module Interface Implementation ---

# describe_node: Describe what this module will install
describe_node() {
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 NODE.JS VIA NVM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This module installs Node.js development environment:

  📦 NVM ${NVM_VERSION}:     Node Version Manager
  🟢 Node.js LTS:        Latest long-term support version
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

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# install_node: Main installation logic
install_node() {
    log "Installing NVM and Node.js LTS..."
    
    # Install NVM if not present
    if [[ ! -d "$NVM_DIR" ]]; then
        log "Installing NVM ${NVM_VERSION}..."
        curl_or_wget_pipe "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" "" "Failed to install NVM" || {
            module_fail "NVM installation failed"
        }
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
    
    # Add NVM to shell RC files
    log "Configuring shell integration..."
    add_nvm_to_shell_rc "${HOME}/.bashrc"
    add_nvm_to_shell_rc "${HOME}/.zshrc"
    
    # Install or update Node LTS
    if ! command_exists node; then
        log "Installing Node.js LTS..."
        # Temporarily disable nounset for NVM (it uses unset variables internally)
        set +u
        run "nvm install --lts" || {
            set -u
            module_fail "Failed to install Node.js LTS"
        }
        set -u
    else
        log "Updating to latest LTS..."
        set +u
        run "nvm install --lts" || warn "LTS update had issues, continuing..."
        run "nvm alias default 'lts/*'" || warn "Failed to set default alias"
        set -u
    fi
    
    # Use LTS version
    set +u
    run "nvm use --lts" || {
        set -u
        module_fail "Failed to switch to LTS version"
    }
    set -u
    
    # Configure npm
    log "Configuring npm..."
    run "npm set fund false" || warn "Failed to disable funding messages"
    run "npm set audit false" || warn "Failed to disable audit"
    run "npm set audit-level moderate" || warn "Failed to set audit level"
    run "npm set loglevel warn" || warn "Failed to set log level"
    
    # Enable Corepack for Yarn & pnpm
    if command_exists corepack; then
        log "Enabling Corepack..."
        run "corepack enable" || warn "Failed to enable Corepack"
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

# add_nvm_to_shell_rc: Add NVM initialization to shell RC file
add_nvm_to_shell_rc() {
    local rc_file="$1"
    
    # Skip if file doesn't exist and we're not in dry-run
    [[ ! -e "$rc_file" ]] && [[ $DRY_RUN -eq 0 ]] && return 0
    
    # Check if NVM block already present
    if [[ -f "$rc_file" ]] && grep -q '# >>> NVM init >>>' "$rc_file"; then
        debug "NVM init already present in ${rc_file}"
        return 0
    fi
    
    log "Adding NVM init to ${rc_file}..."
    
    local nvm_init='
# >>> NVM init >>>
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
# <<< NVM init <<<'
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log "[DRY-RUN] Would append NVM init block to ${rc_file}"
    else
        echo "$nvm_init" >> "$rc_file"
        success "Added NVM init to ${rc_file}"
    fi
}

# verify_node: Verify installation succeeded
verify_node() {
    local failed=0
    
    log "Verifying Node.js installation..."
    
    # Check NVM directory exists
    if [[ ! -d "$NVM_DIR" ]]; then
        error "NVM directory not found: ${NVM_DIR}"
        ((failed++))
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
        ((failed++))
    else
        success "✓ nvm command available"
    fi
    
    # Verify Node.js
    if ! verify_command_exists node; then
        ((failed++))
    fi
    
    # Verify npm
    if ! verify_command_exists npm; then
        ((failed++))
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
