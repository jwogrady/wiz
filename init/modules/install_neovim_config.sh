#!/usr/bin/env bash
# Install AstroNvim config for Neovim
. "$(dirname "$0")/../../lib/common.sh"

log "Setting up AstroNvim (Neovim config)..."
run "git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim"
