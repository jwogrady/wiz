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
# Sourcing:
#   source /path/to/lib/module-base.sh   # then source this file
#
# ==============================================================================

set -euo pipefail

# --- Module Configuration ---
# shellcheck source=../module-base.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../module-base.sh"

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

# Shell init blocks — bash and zsh require different init commands
_STARSHIP_BASH_BLOCK='
# --- Wiz Starship Prompt ---
# Initialize Starship prompt (loads after PATH and other tools)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
# --- End Wiz Starship Prompt ---'

_STARSHIP_ZSH_BLOCK='
# --- Wiz Starship Prompt ---
# Initialize Starship prompt (loads after PATH and other tools)
# Ensure PATH is set before Starship initialization
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
# --- End Wiz Starship Prompt ---'

# --- Module Interface Implementation ---

# describe_starship: Describe what this module will install
describe_starship() {
    _module_banner "✨ STARSHIP PROMPT"
    cat << EOF

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
        
        # Resolve target version: CLI override or latest
        local starship_target="${WIZ_STARSHIP_VERSION:-}"
        local version_flag=""
        if [[ -n "$starship_target" ]]; then
            version_flag=" --version ${starship_target}"
        fi

        # Download installer to temp file, then execute — avoids partial execution
        # on interrupted downloads. Starship does not publish a checksum for
        # install.sh, so we pass empty SHA (wiz_download_verified warns and proceeds).
        local starship_tmp
        starship_tmp="$(wiz_download_verified \
            "https://starship.rs/install.sh" "" \
            "Failed to download Starship installer")" || {
            warn "Official installer download failed, trying alternative methods..."
            install_starship_fallback
            return 0
        }

        if [[ ${WIZ_DRY_RUN:-0} -eq 1 ]]; then
            log "[DRY-RUN] Would execute Starship installer: ${starship_tmp}"
            rm -f "$starship_tmp"
        else
            run_shell "sh '${starship_tmp}' --yes${version_flag}" || {
                rm -f "$starship_tmp"
                warn "Official installer failed, trying alternative methods..."
                install_starship_fallback
                return 0
            }
            rm -f "$starship_tmp"
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
    curl_or_wget_download "$download_url" "$temp_file" \
        "Failed to download starship binary" || return 1

    log "Extracting starship binary..."
    run tar -xzf "$temp_file" -C "$install_dir"
    run chmod +x "$install_dir/starship"
    run rm -f "$temp_file"
    
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
    
    # Check if Nerd Fonts are available FIRST (before copying preset)
    # Improved detection: check multiple patterns and font family names
    local use_nerd_fonts=0
    if command_exists fc-list 2>/dev/null; then
        # Check font family names (more reliable than full font names)
        if fc-list : family | grep -qiE "nerd|hack|fira|meslo|jetbrains|cascadia|dejavu|source.*code|ubuntu.*mono" 2>/dev/null; then
            use_nerd_fonts=1
            debug "Nerd Fonts detected via family names, using full Cosmic Oasis preset"
        # Also check full font names as fallback
        elif fc-list | grep -qiE "nerd|hack.*nerd|fira.*nerd|meslo.*nerd|jetbrains.*nerd" 2>/dev/null; then
            use_nerd_fonts=1
            debug "Nerd Fonts detected via full names, using full Cosmic Oasis preset"
        fi
    fi
    
    # Additional check: If fontconfig shows any fonts with "Nerd" in name
    if [[ $use_nerd_fonts -eq 0 ]] && command_exists fc-list 2>/dev/null; then
        # Check for Nerd Font variants (case insensitive)
        local font_check
        font_check=$(fc-list 2>/dev/null | grep -oi "nerd" | head -1)
        if [[ -n "$font_check" ]]; then
            use_nerd_fonts=1
            debug "Nerd Fonts detected via pattern match, using full Cosmic Oasis preset"
        fi
    fi
    
    # If Nerd Fonts not detected, use fallback immediately
    if [[ $use_nerd_fonts -eq 0 ]]; then
        log "Nerd Fonts not detected, using fallback configuration..."
        create_fallback_config
        return 0
    fi
    
    # Only use the preset if Nerd Fonts are available
    if [[ -f "$STARSHIP_PRESET" ]]; then
        progress "Installing Cosmic Oasis preset (Nerd Fonts detected)..."
        
        # Copy the preset
        if run cp "$STARSHIP_PRESET" "$STARSHIP_CONFIG"; then
            success "Cosmic Oasis preset installed"
        else
            error "Failed to copy preset file"
            warn "Falling back to configuration without Nerd Fonts..."
            create_fallback_config
        fi
    else
        warn "Preset file not found: $STARSHIP_PRESET"
        warn "Creating fallback configuration..."
        create_fallback_config
    fi
    
    log "  ✓ Config saved to: $STARSHIP_CONFIG"
}

# create_fallback_config: Create fallback config without Nerd Fonts
create_fallback_config() {
    log "Creating fallback configuration (no Nerd Fonts required)..."
    cat > "$STARSHIP_CONFIG" << 'EOF'
# 🌌 Cosmic Oasis — Fallback Edition (No Nerd Fonts Required)
# Optimized for terminals without Nerd Fonts

format = """
[░▒▓](#c678dd)\
[ WIZ ](bg:#c678dd fg:#0f0a1f)\
[>](fg:#c678dd bg:#3f2c7e)\
$directory\
[>](fg:#3f2c7e bg:#2e215a)\
$git_branch$git_status\
[>](fg:#2e215a bg:#1e153f)\
$nodejs$bun$rust$golang$php\
[>](fg:#1e153f bg:#0f0a1f)\
$time\
[>](fg:#0f0a1f)\
\n$character"""

# --- Directory ---
[directory]
style = "fg:#EFFFFF bg:#3f2c7e"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

# --- Git ---
[git_branch]
symbol = "branch:"
style = "fg:#C792EA bg:#2e215a"
format = '[[ $symbol $branch ]($style)]($style)'

[git_status]
style = "fg:#7dcfff bg:#2e215a"
format = '[[($all_status$ahead_behind )]($style)]($style)'
conflicted = "="
ahead = "↑${count}"
behind = "↓${count}"
diverged = "⇕↑${ahead_count}↓${behind_count}"
untracked = "?"
stashed = "$"
modified = "!"
staged = "+"
renamed = "»"
deleted = "✘"

# --- Languages ---
[nodejs]
symbol = "⬢"
style = "fg:#7dcfff bg:#1e153f"
format = '[[ $symbol ($version) ]($style)]($style)'

[bun]
symbol = "🥟"
style = "fg:#ff79c6 bg:#1e153f"
format = '[[ $symbol ($version) ]($style)]($style)'
version_format = "v${raw}"

[rust]
symbol = "⚙"
style = "fg:#ff6ac1 bg:#1e153f"
format = '[[ $symbol ($version) ]($style)]($style)'

[golang]
symbol = "🐹"
style = "fg:#92ffb7 bg:#1e153f"
format = '[[ $symbol ($version) ]($style)]($style)'

[php]
symbol = "PHP"
style = "fg:#b4aaff bg:#1e153f"
format = '[[ $symbol ($version) ]($style)]($style)'

# --- Time ---
[time]
disabled = false
time_format = "%R"
style = "fg:#ff6ac1 bg:#0f0a1f"
format = "[ $time ]($style)"

# --- Character ---
[character]
success_symbol = "[>](bold #ff6ac1)"
error_symbol   = "[>](bold #ff5370)"
vimcmd_symbol  = "[<](bold #9ece6a)"
EOF
    
    success "Fallback configuration created"
}

# configure_shell_integration: Add Starship to shell configs
# Ensures Starship loads after PATH is set and other tools are initialized
# Uses wiz_update_shell_block to replace any existing managed block.
# Bash and Zsh require different init commands so each file gets its own block.
configure_shell_integration() {
    log "Configuring shell integration..."

    wiz_update_shell_block \
        "# --- Wiz Starship Prompt ---" \
        "# --- End Wiz Starship Prompt ---" \
        "$_STARSHIP_BASH_BLOCK" \
        "$BASHRC"

    wiz_update_shell_block \
        "# --- Wiz Starship Prompt ---" \
        "# --- End Wiz Starship Prompt ---" \
        "$_STARSHIP_ZSH_BLOCK" \
        "$ZSHRC"

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
