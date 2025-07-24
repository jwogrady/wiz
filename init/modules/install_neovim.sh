#!/usr/bin/env bash
# Install Neovim and AstroNvim config
. "$(dirname "$0")/../../lib/common.sh"

log "Cloning and installing latest Neovim..."
run "git clone https://github.com/neovim/neovim.git ~/neovim"
cd ~/neovim
run "make CMAKE_BUILD_TYPE=Release"
run "sudo make install"
log "Setting up AstroNvim (Neovim config)..."
run "git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim"
