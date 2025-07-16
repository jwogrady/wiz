#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$SCRIPT_DIR/bootstrap"

ENV_FALLBACK="/mnt/c/Users/john/.env"
ENV_DEST="$HOME"

# Copy .env fallback only if it doesn't already exist in ~
if [ ! -f "$HOME/.env" ] && [ -f "$ENV_FALLBACK" ]; then
    cp "$ENV_FALLBACK" "$HOME/.env"
fi

# Source .env if it exists in ~
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    . "$ENV_FILE"
    set +a
fi

# Run scripts in the optimum predefined order
SCRIPTS=(
    "update_upgrade.sh"        # Update and upgrade system packages first
    "install_essentials.sh"    # Install essential packages
    "install_tools.sh"         # Install additional tools
    "load_keys.sh"             # Load SSH or other keys
    "configure_git.sh"         # Configure Git settings
    "backup_default_dots.sh"   # Backup default dotfiles
    "source_dotfiles.sh"       # Restore/symlink dotfiles from backup
    "bootstrap_recap.sh"       # Show recap and welcome message
)

for script_name in "${SCRIPTS[@]}"; do
    script_path="$BOOTSTRAP_DIR/$script_name"
    if [ -f "$script_path" ]; then
        echo "Running $script_path..."
        bash "$script_path"
    else
        echo "Warning: $script_path not found, skipping."
    fi
done
