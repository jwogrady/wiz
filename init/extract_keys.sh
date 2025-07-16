#!/bin/bash
# Copy and extract SSH keys from KEYS_SRC to KEYS_DEST
set -e
. "$HOME/wiz/.env"
if [ -f "$KEYS_SRC" ]; then
    cp "$KEYS_SRC" "$HOME/wiz/keys.tar.gz"
    tar -xzvf "$HOME/wiz/keys.tar.gz" -C "$KEYS_DEST"
    echo "Extracted keys to $KEYS_DEST"
else
    echo "Warning: $KEYS_SRC not found. Skipping key extraction."
fi
