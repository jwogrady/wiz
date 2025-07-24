#!/usr/bin/env bash
# Install Node.js stack (NVM, Node.js, PNPM)

# Log the start of NVM installation
log "Installing NVM (Node Version Manager)..."

# Install NVM if not already installed
if ! command -v nvm &>/dev/null; then
	run "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
	export NVM_DIR="$HOME/.nvm"
	# shellcheck source=/dev/null
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
	log "NVM already installed."
fi

# Install and use the latest Node.js LTS version
log "Installing latest Node.js LTS via NVM..."
run "nvm install --lts"
run "nvm use --lts"

# Install PNPM (alternative Node.js package manager)
log "Installing PNPM (Node.js package manager)..."
run "curl -fsSL https://get.pnpm.io/install.sh | bash -"

# Remind user to add PNPM to PATH if needed
log "PNPM installed. Make sure ~/.local/share/pnpm is in your PATH."
