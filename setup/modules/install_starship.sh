#!/usr/bin/env bash
# Install Starship prompt and configure for Zsh

log "Installing Starship (cross-shell prompt)..."
run "curl -fsSL https://starship.rs/install.sh | bash -s -- -y"

log "Adding Starship init to ~/.zshrc..."
if ! grep -q "eval \"\$(starship init zsh)\"" "$HOME/.zshrc" 2>/dev/null; then
	echo "eval \"\$(starship init zsh)\"" >>"$HOME/.zshrc"
fi
