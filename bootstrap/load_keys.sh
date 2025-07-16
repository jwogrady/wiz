#!/bin/bash

set -e

KEYS_SRC="/mnt/c/Users/john/keys.tar.gz"
KEYS_DEST="$HOME"

if [ -f "$KEYS_SRC" ]; then
    tar -xzvf "$KEYS_SRC" -C "$KEYS_DEST"
    echo "Extracted keys from $KEYS_SRC to $KEYS_DEST"
else
    echo "Warning: $KEYS_SRC not found. Skipping key extraction."
fi