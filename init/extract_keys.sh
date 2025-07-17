#!/bin/bash
# Copy and extract SSH keys from Windows user's home directory to KEYS_DEST
set -e


# Use KEYS_SRC from .env (set by prompt_env.sh)
. "$HOME/wiz/.env"

if [ -f "$KEYS_SRC" ]; then
    cp "$KEYS_SRC" "$HOME/wiz/keys.tar.gz"
    tar -xzvf "$HOME/wiz/keys.tar.gz" -C "$KEYS_DEST"
    echo "Extracted keys to $KEYS_DEST"
else
    echo "Warning: $KEYS_SRC not found. Skipping key extraction."
fi
