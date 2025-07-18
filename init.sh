#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_DIR="$SCRIPT_DIR/init"

# --- INIT PHASE ---
echo
echo "===== WIZ INIT PHASE ====="
echo

INIT_SCRIPTS=(
   "00-prompt-env.sh"      # Prompt for environment variables and write .env
   "10-extract-keys.sh"    # Copy and extract SSH keys
   "20-setup-ssh-agent.sh" # Set up SSH agent auto-load and permissions
   "30-clone-dotfiles.sh"  # Clone dotfiles repo to .backup (skips itself if not enabled)
   "40-clone-wiz.sh"       # Clone the wiz repo
   "50-init-recap.sh"      # Show recap of environment initialization
   "60-recap-init.sh"      # Final recap and next steps
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
