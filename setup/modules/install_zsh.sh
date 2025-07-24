#!/usr/bin/env bash

# Install Zsh

log "Installing Zsh..."

if dpkg -s zsh &>/dev/null; then
	log "zsh is already installed. Skipping."
else
	run "sudo apt install -y zsh"
fi

# Add SSH agent setup to .zshrc if not already present
if ! grep -q 'COSMIC WIZ SSH AGENT' "$HOME/.zshrc" 2>/dev/null; then
	cat <<'EOF' >>"$HOME/.zshrc"

# --- COSMIC WIZ SSH AGENT ---
if [ -z "${SSH_AUTH_SOCK:-}" ] || ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_jwogrady" 2>/dev/null
    ssh-add "$HOME/.ssh/id_vultr" 2>/dev/null
fi
EOF
fi

# Change the default shell to zsh for the current user
log "Changing default shell to zsh for user $USER..."
run "chsh -s '$(command -v zsh)' '$USER'"
