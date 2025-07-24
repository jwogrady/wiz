# --- Ensure running from wiz/init directory ---
if [[ ! -f "./bootstrap.sh" || ! -d "../scripts" || ! -d "./modules" ]]; then
  echo "[ERROR] Please run this script from inside the 'wiz/init' directory (cd ~/wiz/init)."
  exit 1
fi

# Source common utilities
. "$(dirname "$0")/../lib/common.sh"

# ------------------------------------------------------------------------------
# COSMIC WIZ DEVBOX BOOTSTRAP v2.0
# Automated WSL/Unix developer environment setup by @jwogrady
#
# Features:
#   - Installs core dev tools, editors, runtimes, and shell enhancements
#   - Installs OpenAI CLI and GitHub CLI with user-friendly setup
#   - Clones and prepares the wiz repo
#   - Integrates with backup.sh for safe system snapshots
#   - Fully documented, user-friendly, and safe for new users
#
# Usage:
#   ./bootstrap.sh [options]
#   Options:
#     --dry-run         Show commands without executing
#     --help            Show this help message
#
# Prerequisites:
#   - Ubuntu/WSL or compatible Linux
#   - sudo privileges
#   - git, curl, bash
# ------------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'
[ -z "${BASH_VERSION:-}" ] && { echo "❌ Please run this with bash, not sh."; exit 1; }




# --- Globals and Argument Parsing ---
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --help)
      echo -e "\nUsage: $0 [options]"
      echo -e "  --dry-run         Show commands without executing"
      echo -e "  --help            Show this help message"
      exit 0
      ;;
    *) warn "Unknown argument: $arg"; exit 1 ;;
  esac
done




show_banner() {
  echo -e "\n${CYAN}"
  echo "  ╭────────────────────────────────────────────╮"
  echo "  │      🚀 COSMIC WIZ DEVBOX BOOTSTRAP v2.0   │"
  echo "  │       by @jwogrady | status26.com         │"
  echo "  ╰────────────────────────────────────────────╯"
  echo -e "${NC}\n"
}

# --- Essentials: Update and install core utilities ---
install_essentials() {
    log "Updating Ubuntu packages..."
    run "sudo apt update && sudo apt upgrade -y"
    log "Installing essential tools (editors, net, build)..."
    apt_install git vim nano curl net-tools speedtest-cli build-essential cmake tree
}

# --- User local bin path: Ensure ~/.local/bin is in PATH ---
setup_local_bin() {
    log "Adding ~/.local/bin to PATH..."
    mkdir -p "$HOME/.local/bin"
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    fi
    export PATH="$HOME/.local/bin:$PATH"
}

# --- ShellCheck: Build and install latest from source ---
install_shellcheck() {
    log "Installing latest ShellCheck from source..."
    SHELLCHECK_TMP="$HOME/shellcheck-src"
    run "sudo apt-get update"
    run "sudo apt-get install -y git xz-utils cabal-install"
    run "rm -rf \"$SHELLCHECK_TMP\""
    run "git clone --depth 1 https://github.com/koalaman/shellcheck.git \"$SHELLCHECK_TMP\""
    cd "$SHELLCHECK_TMP"
    run "cabal update"
    run "cabal install --installdir=\"$HOME/.local/bin\" --install-method=copy"
    log "ShellCheck version: $($HOME/.local/bin/shellcheck --version | head -n 1)"
    cd ~
    run "rm -rf \"$SHELLCHECK_TMP\""
}

# --- Network & DNS tools: hostmaster, whois, traceroute, etc. ---
install_hostmaster_tools() {
    log "Installing hostmaster, domain, DNS, and internet tools..."
    apt_install bind9-host dnsutils whois traceroute mtr nmap iperf3 netcat-openbsd
}

# --- System Specs & Monitoring: neofetch, lshw, htop, glances, btop ---
install_system_specs_tools() {
    log "Installing system info and monitoring tools..."
    apt_install neofetch lshw htop glances btop
    log "System specs (neofetch):"
    neofetch || echo "neofetch not found"
    log "Hardware summary (lshw -short):"
    sudo lshw -short || echo "lshw not found"
}

# --- Docker & container tools: Docker, Compose, user group ---
install_docker() {
    log "Installing Docker & Compose..."
    apt_install docker.io docker-compose
    run "sudo usermod -aG docker $USER"
    log "Docker installed. Restart WSL or run 'newgrp docker'."
}

# --- Neovim & AstroNvim: Editor and config ---
install_neovim() {
    log "Cloning and installing latest Neovim..."
    run "git clone https://github.com/neovim/neovim.git ~/neovim"
    cd ~/neovim
    run "make CMAKE_BUILD_TYPE=Release"
    run "sudo make install"
    log "Setting up AstroNvim (Neovim config)..."
    run "git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim"
}

# --- Node.js Stack: NVM (version manager) & pnpm (package manager) ---
install_node_stack() {
    log "Installing NVM (Node Version Manager)..."
    if ! command -v nvm &>/dev/null; then
        run "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        log "NVM already installed."
    fi
    log "Installing latest Node.js LTS via NVM..."
    run "nvm install --lts"
    run "nvm use --lts"
    log "Installing PNPM (Node.js package manager)..."
    run "curl -fsSL https://get.pnpm.io/install.sh | bash -"
    log "PNPM installed. Make sure ~/.local/share/pnpm is in your PATH."
}

# --- Bun Stack: Bun JavaScript runtime ---
install_bun() {
    log "Installing Bun (JavaScript runtime)..."
    run "curl -fsSL https://bun.sh/install | bash"
    log "Bun installation complete. Restart your shell or source your profile to use Bun."
}

# --- Starship Prompt & Zsh Terminal: prompt, shell, SSH agent ---
install_starship_zsh() {
    log "Installing Zsh and Starship prompt..."
    apt_install zsh
    log "Installing Starship (cross-shell prompt)..."
    run "curl -fsSL https://starship.rs/install.sh | bash -s -- -y"
    log "Adding Starship init to ~/.zshrc..."
    if ! grep -q 'eval "$(starship init zsh)"' "$HOME/.zshrc" 2>/dev/null; then
        echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
    fi
    # Add SSH agent setup to .zshrc if not already present
    if ! grep -q 'COSMIC WIZ SSH AGENT' "$HOME/.zshrc" 2>/dev/null; then
        cat <<'EOF' >> "$HOME/.zshrc"

# --- COSMIC WIZ SSH AGENT ---
if [ -z "${SSH_AUTH_SOCK:-}" ] || ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_jwogrady" 2>/dev/null
    ssh-add "$HOME/.ssh/id_vultr" 2>/dev/null
fi
EOF
    fi
    log "Changing default shell to zsh for user $USER..."
    run "chsh -s \"$(command -v zsh)\" $USER"
}

# --- Clone wiz repo and run backup script ---
clone_and_backup() {
    local REPO="https://github.com/jwogrady/wiz.git"
    local TARGET="$HOME/wiz"
    if [ ! -d "$TARGET" ]; then
        log "Cloning wiz repo..."
        run "git clone $REPO $TARGET"
    else
        log "wiz repo already exists at $TARGET"
    fi
    if [ -x "$TARGET/scripts/backup.sh" ]; then
        log "Running initial backup script..."
        run "$TARGET/scripts/backup.sh"
    else
        warn "Backup script not found or not executable."
    fi
}


# --- Main execution loop ---
main() {
    show_banner
    log "Starting devbox bootstrap..."

    # Orchestrate all modules
    for module in \
        install_essentials \
        install_shellcheck \
        install_neovim \
        install_hostmaster_tools \
        install_system_specs_tools \
        # install_docker \
        install_node \
        install_bun \
        install_starship_zsh \
        install_openai_cli \
        install_github_cli
    do
        MODULE_PATH="./modules/${module}.sh"
        if [[ -f "$MODULE_PATH" ]]; then
            log "Running module: $module"
            . "$MODULE_PATH"
        else
            warn "Module not found: $MODULE_PATH"
        fi
    done

    # Source aliases
    ALIASES_FILE="./aliases.sh"
    if [ -f "$ALIASES_FILE" ]; then
        log "Sourcing aliases from init directory..."
        . "$ALIASES_FILE"
    else
        warn "Aliases file not found at $ALIASES_FILE."
    fi

    # Run backup script
    if [ -x "../scripts/backup.sh" ]; then
        log "Running backup script..."
        ../scripts/backup.sh
    else
        warn "Backup script not found or not executable."
    fi

    # Source post-install hook if present
    POST_HOOK="../hooks/post_install_custom.sh"
    if [ -f "$POST_HOOK" ]; then
        log "Running post-install custom hook..."
        . "$POST_HOOK"
    fi

    log "\n✅ All developer tools and environment setup complete!"
    echo -e "\n${CYAN}Next steps:${NC}"
    echo "- Review ~/.bashrc and ~/.zshrc for new settings."
    echo "- Restart your shell or run 'exec zsh' to use Zsh and Starship."
    echo "- Use the backup script for safe system snapshots."
    echo "- Happy coding!"
}

# Run main loop
main "$@"

