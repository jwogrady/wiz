#!/usr/bin/env bash
# Install OpenAI CLI
. "$(dirname "$0")/../../lib/common.sh"

log "Installing OpenAI CLI..."
run "pipx install openai"
if ! grep -q 'OPENAI_API_KEY' "$HOME/.env"; then
  read -rp "Enter your OpenAI API key (or leave blank to skip): " OPENAI_API_KEY
  if [[ -n "$OPENAI_API_KEY" ]]; then
    echo "OPENAI_API_KEY=\"$OPENAI_API_KEY\"" >> "$HOME/.env"
    log "OpenAI API key saved to .env"
  fi
fi
