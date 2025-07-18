#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_DIR="$SCRIPT_DIR/init"

# --- INIT PHASE ---
echo
echo "===== WIZ INIT PHASE ====="
echo

INIT_SCRIPTS=(
	"01-prompt_env.sh"      # Prompt for environment variables and write .env
	"02-extract_keys.sh"    # Copy and extract SSH keys
	"03-setup_ssh_agent.sh" # Set up SSH agent auto-load and permissions
	"04-clone_dotfiles.sh"  # Clone dotfiles repo to .backup (skips itself if not enabled)
	"05-clone_wiz.sh"       # Clone the wiz repo
	"06-init_recap.sh"      # Show recap of environment initialization
)
for script_name in "${INIT_SCRIPTS[@]}"; do
	script_path="$INIT_DIR/$script_name"
	if [ -f "$script_path" ]; then
		echo "Running $script_path..."
		bash "$script_path"
	else
		echo "Warning: $script_path not found, skipping."
	fi
	echo
done
echo
echo "===== WIZ init.sh complete! ====="
