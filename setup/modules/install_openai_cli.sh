#!/usr/bin/env bash
# Install OpenAI CLI

# Log the start of the OpenAI CLI installation
log "Installing OpenAI CLI..."

# Install OpenAI CLI using pipx
run "pipx install openai"

# Prompt for OpenAI API key if not already present in .env
if ! grep -q 'OPENAI_API_KEY' "$HOME/.env"; then
	read -rp "Enter your OpenAI API key (or leave blank to skip): " OPENAI_API_KEY
	if [[ -n "$OPENAI_API_KEY" ]]; then
		echo "OPENAI_API_KEY=\"$OPENAI_API_KEY\"" >>"$HOME/.env"
		log "OpenAI API key saved to .env"
	fi
fi
