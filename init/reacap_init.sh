#!/bin/bash
# WIZ Init Recap and Next Steps

set -e

# Recap Section
cat <<EOF

============================
  WIZ Init Recap
============================

EOF

# Check if .env file exists and permissions
if [[ -f "$HOME/wiz/.env" ]]; then
	echo -n "- .env file found: "
	if [[ $(stat -c "%a" "$HOME/wiz/.env") == "600" ]]; then
		echo -e "\e[32mPermissions are correct (600)\e[0m"
	else
		echo -e "\e[31mPermissions are incorrect. Please set to 600.\e[0m"
	fi
else
	echo "- [WARNING] .env file not found. Ensure prompt_env.sh ran successfully."
fi

# Check if SSH keys were extracted and permissions
if [[ -d "$HOME/.ssh" && "$(ls -A $HOME/.ssh 2>/dev/null)" ]]; then
	echo "- SSH keys found in $HOME/.ssh:"
	for key in "$HOME/.ssh/"id_*; do
		[[ "$key" == *.pub ]] && continue
		if [[ -f "$key" ]]; then
			echo -n "  - $(basename "$key"): "
			if [[ $(stat -c "%a" "$key") == "600" ]]; then
				echo -e "\e[32mPermissions are correct (600)\e[0m"
			else
				echo -e "\e[31mPermissions are incorrect. Please set to 600.\e[0m"
			fi
		fi
	done
else
	echo "- [WARNING] SSH keys not found in $HOME/.ssh. Ensure extract_keys.sh ran successfully."
fi

# Check if SSH agent auto-load is configured
if grep -q "SSH agent auto-load" "$HOME/.bashrc"; then
	echo "- SSH agent auto-load was configured (setup_ssh_agent.sh)"
else
	echo "- [WARNING] SSH agent auto-load block not found in .bashrc. Ensure setup_ssh_agent.sh ran successfully."
fi

# Check if dotfiles repo was cloned
if [[ -d "$HOME/.backup" ]]; then
	echo "- Dotfiles repository was cloned to .backup (clone_dotfiles.sh)"
else
	echo "- [WARNING] Dotfiles repository not found in .backup. Ensure clone_dotfiles.sh ran successfully."
fi

# Check if wiz repo was cloned
if [[ -d "$HOME/wiz" ]]; then
	echo "- Wiz repository was cloned to wiz_clone (clone_wiz.sh)"
else
	echo "- [WARNING] Wiz repository not found in wiz_clone. Ensure clone_wiz.sh ran successfully."
fi

# Show backup location if exists
MACHINE_NAME="$(hostname)"
LATEST_BACKUP=$(ls -td $HOME/.backup/$MACHINE_NAME/* 2>/dev/null | head -1)
if [[ -n "$LATEST_BACKUP" ]]; then
	echo "Latest dotfiles backup: $LATEST_BACKUP"
else
	echo "[WARNING] No dotfiles backup found. Ensure backup_default_dots.sh ran successfully."
fi

# Next Steps Section
cat <<EOF

============================
  Next Steps
============================

- Your environment setup is complete. Below are some recommendations:
  1. Review your .env file in $HOME/wiz/.env and update any values if needed.
  2. Verify your SSH keys in $HOME/.ssh and ensure permissions are correct.
  3. Apply your dotfiles from .backup or your dotfiles repo if needed.
  4. Restart your shell or source your profile to apply changes.

EOF

# Final confirmation to proceed to bootstrap
read -rp $'\e[32mIf all checks passed (green), congratulations! You are ready to bootstrap. Press Y or Enter to continue:\e[0m ' CONFIRM_BOOTSTRAP
if [[ -z "$CONFIRM_BOOTSTRAP" || "$CONFIRM_BOOTSTRAP" =~ ^[Yy]$ ]]; then
	echo -e "\e[32mCongratulations! Proceeding to bootstrap...\e[0m"
else
	echo -e "\e[31mBootstrap aborted. Please resolve any issues and try again.\e[0m"
	exit 1
fi
