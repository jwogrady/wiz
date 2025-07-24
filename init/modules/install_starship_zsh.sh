#!/usr/bin/env bash
# Install Zsh and Starship prompt
. "$(dirname "$0")/../../lib/common.sh"

log "Installing Zsh and Starship prompt..."
run "sudo apt install -y zsh"
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
