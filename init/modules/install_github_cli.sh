#!/usr/bin/env bash
# Install GitHub CLI
. "$(dirname "$0")/../../lib/common.sh"

log "Installing GitHub CLI..."
run "sudo apt install -y gh"
if ! gh auth status &>/dev/null; then
  log "Prompting for GitHub CLI authentication..."
  run "gh auth login"
fi
