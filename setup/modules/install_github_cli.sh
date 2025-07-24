#!/usr/bin/env bash
# Install GitHub CLI

# Log the start of the GitHub CLI installation
log "Installing GitHub CLI..."

# Install GitHub CLI using apt
if dpkg -s gh &>/dev/null; then
	log "gh is already installed. Skipping."
else
	run "sudo apt install -y gh"
fi

# Check if GitHub CLI is authenticated; if not, prompt for login
if ! gh auth status &>/dev/null; then
	log "Prompting for GitHub CLI authentication..."
	run "gh auth login"
fi
