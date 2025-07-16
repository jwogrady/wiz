#!/bin/bash
set -e

MACHINE_NAME="$(hostname)"
BACKUP_ROOT="$HOME/.backup/$MACHINE_NAME"

# List available backups
mapfile -t BACKUPS < <(ls -1d "$BACKUP_ROOT"/* 2>/dev/null | sort)
if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo "No backups found for $MACHINE_NAME in $BACKUP_ROOT."
    exit 1
fi

echo "Available backups:"
for i in "${!BACKUPS[@]}"; do
    printf "%2d) %s\n" $((i+1)) "${BACKUPS[$i]}"
done

# Default to the latest backup
DEFAULT_INDEX=$((${#BACKUPS[@]}))
read -p "Select a backup to source [default: $DEFAULT_INDEX]: " CHOICE

if [[ -z "$CHOICE" ]]; then
    CHOICE=$DEFAULT_INDEX
fi

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#BACKUPS[@]}" ]; then
    echo "Invalid selection."
    exit 1
fi

SELECTED_BACKUP="${BACKUPS[$((CHOICE-1))]}"
echo "Restoring dotfiles from $SELECTED_BACKUP..."

for file in "$SELECTED_BACKUP"/.*; do
    name="$(basename "$file")"
    [[ "$name" =~ ^\.(\.|)$ ]] && continue
    target="$HOME/$name"
    if [ -e "$target" ] || [ -L "$target" ]; then
        rm -f "$target"
    fi
    ln -sv "$file" "$target"
done

echo
