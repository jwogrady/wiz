#!/usr/bin/env bash
# ==============================================================================
# Wiz - Terminal Magic Module: Starship Prompt
# ==============================================================================
# Installs and configures Starship cross-shell prompt with custom Cosmic Oasis preset.
# Features seamless gradient transitions with polished appearance.
#
# Provides:
#   - Starship prompt with custom gradient theme
#   - Cosmic Oasis - Polished Crescent Edition preset
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
MODULE_DESCRIPTION="Starship cross-shell prompt with Cosmic Oasis preset"
MODULE_DEPS="zsh"

# Configuration
STARSHIP_CONFIG="$HOME/.config/starship.toml"
ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"
# WIZ_ROOT is already set by module-base.sh (which sources common.sh)
# Use the existing WIZ_ROOT instead of redefining it
STARSHIP_PRESET="${WIZ_ROOT}/config/starship_linux.toml"

# --- Module Interface Implementation ---

# describe_starship: Describe what this module will install
describe_starship() {
    cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ STARSHIP PROMPT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This module installs Starship with the Cosmic Oasis preset:

  🚀 Fast & Minimal:     Written in Rust, blazing fast
  🎨 Cosmic Oasis:       Custom gradient theme with polished appearance
  🐚 Cross-Shell:        Works in Zsh, Bash, Fish, etc.
  ⚙️  Smart Context:      Shows git, node, bun, rust, golang info
  🎯 Customizable:       TOML-based configuration

Features:
  - Seamless gradient transitions
  - Git branch and status
  - Directory path with truncation
  - Language version detection (Node, Bun, Rust, Go, PHP)
  - Time display
  - Exit status indicator

Cosmic Oasis - Polished Crescent Edition with perfectly matched gradient joins.

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
        
        # Download and run installer directly with proper arguments
        if command_exists curl; then
            run "curl -sS https://starship.rs/install.sh | sh -s -- --yes" || {
                warn "curl installation failed, trying wget..."
                if command_exists wget; then
                    run "wget -qO- https://starship.rs/install.sh | sh -s -- --yes" || {
                        warn "Official installer failed, trying alternative methods..."
                        install_starship_fallback
                    }
                else
                    warn "Official installer failed, trying alternative methods..."
                    install_starship_fallback
                fi
            }
        elif command_exists wget; then
            run "wget -qO- https://starship.rs/install.sh | sh -s -- --yes" || {
                warn "Official installer failed, trying alternative methods..."
                install_starship_fallback
            }
        else
            warn "Neither curl nor wget available, trying alternative methods..."
            install_starship_fallback
        fi
        
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
    # Try downloading the binary directly as a more reliable fallback
    log "Trying direct binary download..."
    
    local install_dir="${HOME}/.local/bin"
    mkdir -p "$install_dir"
    
    # Detect architecture
    local arch
    arch="$(uname -m)"
    local starship_arch
    
    case "$arch" in
        "x86_64")
            starship_arch="x86_64-unknown-linux-gnu"
        ;;
        "aarch64"|"arm64")
            starship_arch="aarch64-unknown-linux-gnu"
        ;;
        *)
            error "Unsupported architecture: $arch"
            return 1
        ;;
    esac
    
    local download_url="https://github.com/starship/starship/releases/latest/download/starship-${starship_arch}.tar.gz"
    local temp_file="/tmp/starship.tar.gz"
    
    log "Downloading starship binary for ${starship_arch}..."
    
    if command_exists curl; then
        run "curl -fsSL -o '$temp_file' '$download_url'" || {
            error "Failed to download starship binary"
            return 1
        }
    elif command_exists wget; then
        run "wget -q -O '$temp_file' '$download_url'" || {
            error "Failed to download starship binary"
            return 1
        }
    else
        error "Neither curl nor wget available"
        return 1
    fi
    
    log "Extracting starship binary..."
    run "tar -xzf '$temp_file' -C '$install_dir'"
    run "chmod +x '$install_dir/starship'"
    run "rm -f '$temp_file'"
    
    # Add to PATH
    add_to_path "$install_dir"
    
    if command_exists starship; then
        success "Starship installed via direct binary download"
        return 0
    else
        error "Starship installation failed"
        return 1
    fi
}

# configure_starship_config: Install custom Cosmic Oasis preset
configure_starship_config() {
    log "Configuring Starship with Cosmic Oasis preset..."
    
    # Create config directory
    mkdir -p "$(dirname "$STARSHIP_CONFIG")"
    
    # Backup existing config
    if [[ -f "$STARSHIP_CONFIG" ]]; then
        backup_file "$STARSHIP_CONFIG"
        log "Existing config backed up"
    fi
    
    # Use custom preset from backup directory
    if [[ -f "$STARSHIP_PRESET" ]]; then
        progress "Installing Cosmic Oasis preset..."
        if run "cp '$STARSHIP_PRESET' '$STARSHIP_CONFIG'"; then
            success "Cosmic Oasis preset installed"
        else
            error "Failed to copy preset file"
            warn "Falling back to manual configuration..."
            create_manual_config
        fi
    else
        warn "Preset file not found: $STARSHIP_PRESET"
        warn "Falling back to manual configuration..."
        create_manual_config
    fi
    
    log "  ✓ Config saved to: $STARSHIP_CONFIG"
}

# create_manual_config: Create manual fallback configuration
create_manual_config() {
    log "Creating fallback configuration..."
    cat > "$STARSHIP_CONFIG" << 'EOF'
# ~/.config/starship.toml
# Starship configuration - Fallback (WSL-friendly)
# Generated by Wiz - Terminal Magic
# Note: Custom preset not found, using basic configuration

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
