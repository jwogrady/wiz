#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
BOOTSTRAP_DIR="$SCRIPT_DIR/bootstrap"

# --- WIZ BOOTSTRAP PHASE ---
echo
echo "===== WIZ BOOTSTRAP PHASE ====="
echo
BOOTSTRAP_SCRIPTS=(
    "update_upgrade.sh"        # Update and upgrade system packages first
    "install_essentials.sh"    # Install essential packages
    "install_tools.sh"         # Install additional tools
    "load_keys.sh"             # Load SSH or other keys
    "configure_git.sh"         # Configure Git settings
    "backup_default_dots.sh"   # Backup default dotfiles
    "source_dotfiles.sh"       # Restore/symlink dotfiles from backup
    "recap_bootstrap.sh"       # Show recap and welcome message
)
for script_name in "${BOOTSTRAP_SCRIPTS[@]}"; do
    script_path="$BOOTSTRAP_DIR/$script_name"
    if [ -f "$script_path" ]; then
        # Only run if not already completed (idempotency check for some steps)
        case "$script_name" in
            "backup_default_dots.sh")
                # Only backup if backup for today doesn't exist
                MACHINE_NAME="$(hostname)"
                TODAY="$(date +'%Y-%m-%d')"
                if ls $HOME/.backup/$MACHINE_NAME/${TODAY}_* 1> /dev/null 2>&1; then
                    echo "Backup for today already exists, skipping $script_name."
                    continue
                fi
                ;;
            "bootstrap_recap.sh")
                # Always show recap
                ;;
        esac
        echo "Running $script_path..."
        bash "$script_path"
    else
        echo "Warning: $script_path not found, skipping."
    fi
    echo
done
echo
echo "===== WIZ bootstrap.sh complete! ====="
echo
