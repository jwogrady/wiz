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
# Sourcing:
#   source /path/to/lib/module-base.sh   # then source this file
#
# ==============================================================================

set -euo pipefail

# --- Module Configuration ---
# shellcheck source=../module-base.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../module-base.sh"

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
    _module_banner "🐚 ZSH CONFIGURATION"
    cat << EOF

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
        
        # Download installer to temp file then execute — avoids partial execution
        # on interrupted downloads. download_to_temp handles curl/wget fallback.
        local omz_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
        local omz_tmp
        omz_tmp="$(download_to_temp "$omz_url" "Failed to download Oh My Zsh installer")" || {
            module_fail "Oh My Zsh download failed"
        }
        run_shell "sh '$omz_tmp' --unattended" || {
            rm -f "$omz_tmp"
            module_fail "Failed to install Oh My Zsh"
        }
        rm -f "$omz_tmp"
        
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
    if grep -q "^plugins=" "$ZSHRC" 2>/dev/null; then
        log "Updating plugins configuration..."
        sed_inplace 's/^plugins=(.*)/plugins=(git colored-man-pages extract)/' "$ZSHRC"
    else
        log "Adding plugins configuration..."
        cat >> "$ZSHRC" << 'EOF'

# --- Wiz Zsh Configuration ---
plugins=(git colored-man-pages extract)
# --- End Wiz Zsh Configuration ---
EOF
    fi
    
    # Set as default shell (if not already)
    local current_shell
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"
    
    if [[ "$current_shell" != "$(command -v zsh)" ]]; then
        log "Setting Zsh as default shell..."
        # Get zsh path first, then pass to run safely
        local zsh_path
        zsh_path="$(command -v zsh)"
        run sudo chsh -s "$zsh_path" "$USER" || warn "Could not change default shell"
        success "Zsh set as default shell (will take effect on next login)"
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

