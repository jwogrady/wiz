#!/usr/bin/env bash
# ==============================================================================
# Wiz Module: Zsh Configuration
# ==============================================================================
# Configures Zsh as the default shell with Oh My Zsh framework.
#
# Provides:
#   - Zsh shell (installed by essentials)
#   - Oh My Zsh framework
#   - Common plugins and themes
#
# Dependencies: essentials (for zsh installation)
#
# Usage:
#   ./install_zsh.sh
#   or sourced by bootstrap orchestrator
#
# ==============================================================================

set -euo pipefail

# --- Module Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source module base
# shellcheck source=lib/module-base.sh
source "${SCRIPT_DIR}/../module-base.sh"

# Module metadata
MODULE_NAME="zsh"
MODULE_VERSION="0.2.0"
MODULE_DESCRIPTION="Zsh shell with Oh My Zsh framework"
MODULE_DEPS="essentials"

# Configuration
ZSHRC="$HOME/.zshrc"
OHMYZSH_DIR="$HOME/.oh-my-zsh"

# --- Module Interface Implementation ---

# describe_zsh: Describe what this module will install
describe_zsh() {
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🐚 ZSH CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This module configures Zsh as your default shell:

  🐚 Zsh Shell:          Powerful shell with advanced features
  🎨 Oh My Zsh:         Community-driven framework
  🔌 Plugins:            Git, colored-man-pages, extract
  🎯 Theme:              robbyrussell (default, clean)

Features:
  - Tab completion
  - Command history
  - Directory navigation
  - Git integration
  - Syntax highlighting ready

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# install_zsh: Main installation logic
install_zsh() {
    # Verify zsh is installed
    if ! command_exists zsh; then
        module_fail "Zsh is not installed (should be installed by essentials module)"
    fi
    
    log "Configuring Zsh..."
    
    # Install Oh My Zsh if not present
    if [[ ! -d "$OHMYZSH_DIR" ]]; then
        log "Installing Oh My Zsh..."
        
        # Download and run installer with --unattended flag
        if command_exists curl; then
            run "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended" || {
                warn "curl installation failed, trying wget..."
                if command_exists wget; then
                    run "sh -c \"\$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended" || {
                        module_fail "Failed to install Oh My Zsh"
                    }
                else
                    module_fail "Neither curl nor wget available"
                fi
            }
        elif command_exists wget; then
            run "sh -c \"\$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended" || {
                module_fail "Failed to install Oh My Zsh"
            }
        else
            module_fail "Neither curl nor wget available"
        fi
        
        success "Oh My Zsh installed"
    else
        log "Oh My Zsh already installed"
    fi
    
    # Configure .zshrc with useful plugins
    if [[ -f "$ZSHRC" ]]; then
        backup_file "$ZSHRC"
    fi
    
    log "Configuring .zshrc..."
    
    # Create or update .zshrc with common plugins
    if ! grep -q "plugins=" "$ZSHRC" 2>/dev/null; then
        log "Adding plugins configuration..."
        sed -i 's/^plugins=(.*)/plugins=(git colored-man-pages extract)/' "$ZSHRC" 2>/dev/null || {
            # If sed failed, append configuration
            cat >> "$ZSHRC" <<'EOF'

# --- Wiz Zsh Configuration ---
plugins=(git colored-man-pages extract)
# --- End Wiz Zsh Configuration ---
EOF
        }
    fi
    
    # Set as default shell (if not already)
    local current_shell
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"
    
    if [[ "$current_shell" != "$(command -v zsh)" ]]; then
        log "Setting Zsh as default shell..."
        run "chsh -s $(command -v zsh)" || warn "Could not change default shell (may require password)"
        success "Zsh set as default shell"
    else
        debug "Zsh already set as default shell"
    fi
    
    success "Zsh configuration complete"
    
    return 0
}

# verify_zsh: Verify installation succeeded
verify_zsh() {
    log "Verifying Zsh installation..."
    
    local failed=0
    
    # Check zsh command exists
    if ! verify_command_exists zsh; then
        ((failed++))
    fi
    
    # Check Oh My Zsh directory
    if ! verify_file_or_dir "$OHMYZSH_DIR" "Oh My Zsh directory"; then
        ((failed++))
    fi
    
    # Check .zshrc exists
    verify_file_or_dir "$ZSHRC" ".zshrc" 1
    
    if [[ $failed -gt 0 ]]; then
        error "Verification failed with ${failed} error(s)"
        return 1
    fi
    
    success "Zsh installation verified successfully"
    return 0
}

# --- Main Execution ---

# If script is executed directly (not sourced), run the module
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    execute_module "zsh"
fi

