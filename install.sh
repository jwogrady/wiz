#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_DIR="$SCRIPT_DIR/init"
BOOTSTRAP_DIR="$SCRIPT_DIR/bootstrap"

# --- INIT PHASE ---
echo "\n===== aweMe INIT PHASE =====\n"
INIT_SCRIPTS=(
    "prompt_env.sh"        # Prompt for environment variables and write .env
    "extract_keys.sh"      # Copy and extract SSH keys
    "setup_ssh_agent.sh"   # Set up SSH agent auto-load and permissions
    "clone_dotfiles.sh"    # Clone dotfiles repo to .backup
    "clone_wiz.sh"         # Clone the wiz repo
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

# --- BOOTSTRAP PHASE ---
echo "\n===== aweMe BOOTSTRAP PHASE =====\n"
BOOTSTRAP_SCRIPTS=(
    "update_upgrade.sh"        # Update and upgrade system packages first
    "install_essentials.sh"    # Install essential packages
    "install_tools.sh"         # Install additional tools
    "load_keys.sh"             # Load SSH or other keys
    "configure_git.sh"         # Configure Git settings
    "backup_default_dots.sh"   # Backup default dotfiles
    "source_dotfiles.sh"       # Restore/symlink dotfiles from backup
    "bootstrap_recap.sh"       # Show recap and welcome message
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

echo "\n===== aweMe install.sh complete! =====\n"
