#!/usr/bin/env bash
# Install Node.js stack (NVM, Node.js, PNPM)
. "$(dirname "$0")/../../lib/common.sh"

log "Installing NVM (Node Version Manager)..."
if ! command -v nvm &>/dev/null; then
  run "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
  log "NVM already installed."
fi
log "Installing latest Node.js LTS via NVM..."
run "nvm install --lts"
run "nvm use --lts"
log "Installing PNPM (Node.js package manager)..."
run "curl -fsSL https://get.pnpm.io/install.sh | bash -"
log "PNPM installed. Make sure ~/.local/share/pnpm is in your PATH."
