#!/usr/bin/env bash
# ==============================================================================
# Wiz Module: Starship Prompt
# ==============================================================================
# Installs and configures Starship cross-shell prompt with No Nerd Font preset.
# Perfect for WSL environments where nerd fonts may not be available.
#
# Provides:
#   - Starship prompt with clean, modern appearance
#   - No Nerd Font preset (uses standard symbols)
#   - Shell integration for Zsh and Bash
#
# Dependencies: zsh (for optimal experience)
#
# Usage:
#   ./install_starship.sh
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
MODULE_NAME="starship"
MODULE_VERSION="0.2.0"
MODULE_DESCRIPTION="Starship cross-shell prompt with No Nerd Font preset"
MODULE_DEPS="zsh"

# Configuration
STARSHIP_CONFIG="$HOME/.config/starship.toml"
ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"

# --- Module Interface Implementation ---

# describe_starship: Describe what this module will install
describe_starship() {
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ STARSHIP PROMPT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This module installs Starship, a minimal and fast prompt:

  🚀 Fast & Minimal:     Written in Rust, blazing fast
  🎨 No Nerd Fonts:      Works without special fonts (WSL-friendly)
  🐚 Cross-Shell:        Works in Zsh, Bash, Fish, etc.
  ⚙️  Smart Context:      Shows git, node, python, rust info
  🎯 Customizable:       TOML-based configuration

Features:
  - Git branch and status
  - Directory path with truncation
  - Language version detection (Node, Python, Rust)
  - Command execution time
  - Exit status indicator
  - Battery status

Perfect for WSL environments without Nerd Fonts installed.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# install_starship: Main installation logic
install_starship() {
    # Check if starship is already installed
    local already_installed=0
    if check_command_installed starship; then
        already_installed=1
        log "Starship already installed, updating configuration..."
    fi
    
    # Install starship if not present
    if [[ $already_installed -eq 0 ]]; then
        log "Installing Starship prompt..."
        
        # Install via official installer
        progress "Downloading Starship installer..."
        
        curl_or_wget_pipe "https://starship.rs/install.sh" "-- --yes" "Failed to install Starship via official installer" || {
            warn "Official installer failed, trying alternative methods..."
            install_starship_fallback
        }
        
        # Verify installation
        if ! command_exists starship; then
            module_fail "Starship installation failed"
        fi
        
        local version
        version="$(get_command_version starship)"
        success "Starship installed: v${version}"
    fi
    
    # Always configure prompt (even if already installed)
    configure_starship_config
    configure_shell_integration
    
    return 0
}

# install_starship_fallback: Alternative installation methods
install_starship_fallback() {
    if command_exists apt; then
        warn "Trying apt installation..."
        run "sudo apt-get update"
        run "sudo apt-get install -y starship" || {
            error "Apt installation also failed"
            return 1
        }
    else
        error "No suitable installation method found"
        return 1
    fi
}

# configure_starship_config: Create No Nerd Font configuration
configure_starship_config() {
    log "Configuring Starship with No Nerd Font preset..."
    
    # Create config directory
    mkdir -p "$(dirname "$STARSHIP_CONFIG")"
    
    # Backup existing config
    if [[ -f "$STARSHIP_CONFIG" ]]; then
        backup_file "$STARSHIP_CONFIG"
        log "Existing config backed up"
    fi
    
    # Apply No Nerd Font preset
    if command_exists starship; then
        progress "Applying No Nerd Font preset..."
        
        # Download preset directly (force overwrite)
        if starship preset no-nerd-font -o "$STARSHIP_CONFIG" </dev/null 2>/dev/null; then
            success "No Nerd Font preset applied"
        else
            warn "Failed to apply preset, creating manual configuration..."
            create_manual_config
        fi
    else
        create_manual_config
    fi
    
    log "  ✓ Config saved to: $STARSHIP_CONFIG"
}

# create_manual_config: Create manual No Nerd Font configuration
create_manual_config() {
    cat > "$STARSHIP_CONFIG" <<'EOF'
# ~/.config/starship.toml
# Starship configuration - No Nerd Font preset (WSL-friendly)
# Generated by Wiz - Terminal Magic

# Timeout for commands (milliseconds)
command_timeout = 1000

# Format string
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$nodejs\
$python\
$rust\
$golang\
$cmd_duration\
$line_break\
$character"""

# Character symbols (no nerd fonts)
[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"
vimcmd_symbol = "[<](bold green)"

# Directory
[directory]
truncation_length = 3
truncate_to_repo = true
format = "[$path]($style)[$read_only]($read_only_style) "
style = "bold cyan"
read_only = " "

# Git branch
[git_branch]
symbol = ""
format = "on [$symbol$branch]($style) "
style = "bold purple"

# Git status
[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold red"
conflicted = "="
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
untracked = "?"
stashed = "$"
modified = "!"
staged = "+"
renamed = "»"
deleted = "✘"

# Node.js
[nodejs]
symbol = "[⬢](bold green) "
format = "via [$symbol($version )]($style)"
detect_extensions = ["js", "mjs", "cjs", "ts"]

# Python
[python]
symbol = "🐍 "
format = "via [${symbol}${pyenv_prefix}(${version} )]($style)"

# Rust
[rust]
symbol = "⚙ "
format = "via [$symbol($version )]($style)"

# Go
[golang]
symbol = "🐹 "
format = "via [$symbol($version )]($style)"

# Command duration
[cmd_duration]
min_time = 500
format = "took [$duration]($style) "
style = "bold yellow"

# Battery
[battery]
full_symbol = "• "
charging_symbol = "⇡ "
discharging_symbol = "⇣ "
unknown_symbol = "? "
empty_symbol = "! "

[[battery.display]]
threshold = 30
style = "bold red"

[[battery.display]]
threshold = 50
style = "bold yellow"

[[battery.display]]
threshold = 80
style = "bold green"

# Time (disabled by default)
[time]
disabled = true
format = "🕒 [$time]($style) "
time_format = "%H:%M:%S"

# Username
[username]
show_always = false
format = "[$user]($style)@"
style_user = "bold yellow"

# Hostname
[hostname]
ssh_only = false
format = "[$hostname]($style) in "
style = "bold green"
disabled = false
EOF
    
    success "Manual configuration created"
}

# configure_shell_integration: Add Starship to shell configs
configure_shell_integration() {
    log "Configuring shell integration..."
    
    local starship_init='
# --- Wiz Starship Prompt ---
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
# --- End Wiz Starship Prompt ---
'
    
    local starship_zsh_init='
# --- Wiz Starship Prompt ---
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
# --- End Wiz Starship Prompt ---
'
    
    # Add to Bash
    if [[ -f "$BASHRC" ]]; then
        append_to_file_once "$BASHRC" "Wiz Starship Prompt" "$starship_init"
        debug "Starship init added to .bashrc"
    fi
    
    # Add to Zsh
    if [[ -f "$ZSHRC" ]]; then
        append_to_file_once "$ZSHRC" "Wiz Starship Prompt" "$starship_zsh_init"
        debug "Starship init added to .zshrc"
    fi
    
    success "Shell integration configured"
}

# verify_starship: Verify installation succeeded
verify_starship() {
    log "Verifying Starship installation..."
    
    local failed=0
    
    # Check if command exists
    if ! verify_command_exists starship; then
        ((failed++))
    fi
    
    # Check config file exists
    if ! verify_file_or_dir "$STARSHIP_CONFIG" "Starship config file"; then
        ((failed++))
    fi
    
    # Validate config (optional)
    if command_exists starship && starship config </dev/null 2>/dev/null | grep -q "format"; then
        debug "  ✓ Config file valid"
    else
        debug "Config validation skipped"
    fi
    
    if [[ $failed -gt 0 ]]; then
        error "Verification failed with ${failed} error(s)"
        return 1
    fi
    
    success "Starship installation verified successfully"
    return 0
}

# --- Main Execution ---

# If script is executed directly (not sourced), run the module
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    execute_module "starship"
fi
