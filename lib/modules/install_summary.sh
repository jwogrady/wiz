#!/usr/bin/env bash
# ==============================================================================
# Wiz Module: Installation Summary
# ==============================================================================
# Displays a summary of the installation and provides next steps.
#
# Provides:
#   - Installation summary
#   - Next steps information
#   - System information
#
# Dependencies: ALL (runs after all other modules)
#
# Usage:
#   ./install_summary.sh
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
MODULE_NAME="summary"
MODULE_VERSION="0.2.0"
MODULE_DESCRIPTION="Display installation summary and next steps"
MODULE_DEPS="ALL"

# --- Module Interface Implementation ---

# describe_summary: Describe what this module will do
describe_summary() {
    cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 INSTALLATION SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This module displays a summary of your installation:

  ✅ Installed modules
  📝 Configuration files
  🔧 Installed tools
  📚 Next steps

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# install_summary: Main installation logic
install_summary() {
    log "Generating installation summary..."
    
    # Display summary
    show_installation_summary
    
    return 0
}

# show_installation_summary: Display comprehensive summary
show_installation_summary() {
    echo ""
    success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    success "  INSTALLATION SUMMARY"
    success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Installed modules
    log "Installed Modules:"
    local modules_installed=0
    # SCRIPT_DIR already points to lib/modules, so use it directly
    local modules_dir="${SCRIPT_DIR}"
    for module_file in "${modules_dir}"/install_*.sh; do
        [[ -f "$module_file" ]] || continue
        
        local module_name
        module_name="$(basename "$module_file" .sh)"
        module_name="${module_name#install_}"
        
        if is_module_complete "$module_name"; then
            echo "  ✓ $module_name"
            ((modules_installed++))
        fi
    done
    
    if [[ $modules_installed -eq 0 ]]; then
        echo "  (none)"
    fi
    
    echo ""
    
    # Installed tools
    log "Installed Tools:"
    local tools_checked=0
    local tools_found=0
    
    for tool in git curl wget node npm nvm zsh starship nvim docker; do
        ((tools_checked++))
        if command_exists "$tool"; then
            local version
            version="$(get_command_version "$tool")"
            [[ "$version" != "unknown" ]] && version=" v${version}" || version=""
            echo "  ✓ $tool${version}"
            ((tools_found++))
        fi
    done
    
    if [[ $tools_found -eq 0 ]]; then
        echo "  (none detected)"
    fi
    
    echo ""
    
    # Configuration files
    log "Configuration Files:"
    local configs_found=0
    
    for config in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.config/starship.toml" "$HOME/.config/nvim/init.lua" "$HOME/.nvm"; do
        if [[ -e "$config" ]]; then
            echo "  ✓ $config"
            ((configs_found++))
        fi
    done
    
    if [[ $configs_found -eq 0 ]]; then
        echo "  (none)"
    fi
    
    echo ""
    
    # Next steps
    log "Next Steps:"
    echo "  1. Restart your terminal or run: ${BOLD}source ~/.zshrc${NC}"
    echo "  2. Verify tools are working: ${BOLD}node --version${NC}, ${BOLD}nvim --version${NC}"
    echo "  3. Configure your editor: ${BOLD}nvim ~/.config/nvim/init.lua${NC}"
    echo "  4. Customize Starship: ${BOLD}nvim ~/.config/starship.toml${NC}"
    echo ""
    
    success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# verify_summary: Verify installation succeeded
verify_summary() {
    # Summary module always succeeds (it's just informational)
    return 0
}

# --- Main Execution ---

# If script is executed directly (not sourced), run the module
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    execute_module "summary"
fi

