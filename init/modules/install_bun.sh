#!/usr/bin/env bash
# Install Bun JavaScript runtime
. "$(dirname "$0")/../../lib/common.sh"

log "Installing Bun (JavaScript runtime)..."
run "curl -fsSL https://bun.sh/install | bash"
log "Bun installation complete. Restart your shell or source your profile to use Bun."
