#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Wiz - Terminal Magic: Dotfile Backup Script
# Backs up key user dotfiles to a timestamped directory in ~/.backup/
# Called by ../init/bootstrap.sh
# ------------------------------------------------------------------------------

set -euo pipefail

# Create backup directory with timestamp
BACKUP_DIR="$HOME/.backup/backup_$(date '+%Y%m%d_%H%M%S')"
mkdir -p "$BACKUP_DIR"

# List of dotfiles to backup
DOTFILES=(".bash_logout" ".bashrc" ".profile" ".wget-hsts")

# Copy each dotfile if it exists
for file in "${DOTFILES[@]}"; do
  if [ -f "$HOME/$file" ]; then
    cp "$HOME/$file" "$BACKUP_DIR/"
    echo "Backed up $file to $BACKUP_DIR"
  else
    echo "File $file does not exist, skipping."
  fi
done

echo "Backup complete. Backup location: $BACKUP_DIR"
