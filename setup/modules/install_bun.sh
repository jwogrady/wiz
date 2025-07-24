#!/usr/bin/env bash
# Install Bun JavaScript runtime

# Log the start of the Bun installation process
log "Installing Bun (JavaScript runtime)..."

# Download and run the official Bun install script from bun.sh
# This will install Bun to the user's home directory (by default)
if ! command -v bun &>/dev/null; then
	run "curl -fsSL https://bun.sh/install | bash"
else
	log "Bun is already installed. Skipping installation."
fi

# Inform the user that installation is complete and remind them to restart their shell
log "Bun installation complete. Restart your shell or source your profile to use Bun."
