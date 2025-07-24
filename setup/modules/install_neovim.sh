#!/usr/bin/env bash

# Install Neovim and AstroNvim config
# NOTE: This repository is NOT a direct Neovim config. It only automates setup and clones AstroNvim if needed.

# Only clone and build Neovim if not already installed
if ! command -v nvim &>/dev/null; then
	NEOVIM_SRC="$HOME/code/neovim"
	prepare_code_repo "$NEOVIM_SRC"
	log "Cloning Neovim source into $NEOVIM_SRC..."
	run "git clone https://github.com/neovim/neovim.git '$NEOVIM_SRC'"
	cd "$NEOVIM_SRC" || exit
	run "make CMAKE_BUILD_TYPE=Release"
	run "sudo make install"
else
	log "Neovim binary already exists at $(command -v nvim)."
	echo -n "Neovim is already installed. Reinstall? (y/N, auto-skip in 10s): "
	read -t 10 REPLY
	if [[ "$REPLY" =~ ^[Yy]$ ]]; then
		NEOVIM_SRC="$HOME/code/neovim"
		prepare_code_repo "$NEOVIM_SRC"
		log "Cloning Neovim source into $NEOVIM_SRC..."
		run "git clone https://github.com/neovim/neovim.git '$NEOVIM_SRC'"
		cd "$NEOVIM_SRC" || exit
		run "make CMAKE_BUILD_TYPE=Release"
		run "sudo make install"
	else
		log "Skipping Neovim reinstall."
	fi
fi

# Log the start of AstroNvim config setup
log "Setting up AstroNvim (Neovim config)..."


# Remove existing Neovim config and data folders
run "rm -rf $HOME/.config/nvim"
run "rm -rf $HOME/.local/share/nvim"
run "rm -rf $HOME/.local/state/nvim"
run "rm -rf $HOME/.cache/nvim"

# Clone AstroNvim template
run "git clone --depth 1 https://github.com/AstroNvim/template $HOME/.config/nvim"
run "rm -rf $HOME/.config/nvim/.git"
