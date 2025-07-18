#!/bin/bash
# Clone dotfiles repo to .backup
envfile="$HOME/wiz/.env"
if [ -f "$envfile" ]; then
	. "$envfile"
	if [[ ! "$USE_DOTFILES_REPO" =~ ^[Yy]$ ]]; then
		echo "Skipping dotfiles repo clone as requested."
		exit 0
	fi
	# If already in the wiz folder, skip clone
	cwd=$(pwd)
	if [[ "$cwd" == "$HOME/wiz" ]]; then
		echo "Already in the wiz folder, skipping clone."
		exit 0
	fi
	# If ~/wiz does not exist, clone to ~/wiz
	if [ ! -d "$HOME/wiz" ]; then
		git clone "$GITHUB_DOTFILES_REPO_URL" "$HOME/wiz" || echo "$HOME/wiz already exists."
	else
		echo "$HOME/wiz already exists, skipping clone."
	fi
else
	echo ".env file not found. Cannot clone dotfiles."
fi
