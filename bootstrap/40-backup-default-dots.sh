#!/bin/bash

# Get machine name and timestamp
MACHINE_NAME="$(hostname)"
TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"

# Backup directory structure: ~/.backup/<machine>/<timestamp>
BACKUP_DIR="$HOME/.backup/$MACHINE_NAME/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

DOTFILES=(.bashrc .profile .bash_profile .zshrc .vimrc .gitconfig)

found_any=0
for file in "${DOTFILES[@]}"; do
	if [ -f "$HOME/$file" ]; then
		# If it's a symlink, copy the target file, else copy the file itself
		if [ -L "$HOME/$file" ]; then
			target="$(readlink -f "$HOME/$file")"
			cp "$target" "$BACKUP_DIR/$file"
			echo "Backed up symlink target of $file to $BACKUP_DIR/"
		else
			cp "$HOME/$file" "$BACKUP_DIR/"
			echo "Backed up $file to $BACKUP_DIR/"
		fi
		found_any=1
	fi
done

if [ "$found_any" -eq 0 ]; then
	echo "No dotfiles found to back up."
fi
