#!/bin/bash

# WIZ Full Dry Run
# Simulates both INIT and BOOTSTRAP phases, showing what would be run without making changes.


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
INIT_DIR="$SCRIPT_DIR/init"
BOOTSTRAP_DIR="$SCRIPT_DIR/bootstrap"

# Ensure all scripts are executable before dry run
chmod +x "$INIT_DIR"/*.sh "$BOOTSTRAP_DIR"/*.sh 2>/dev/null

echo
echo "===== WIZ INIT DRY RUN ====="
echo
INIT_SCRIPTS=(
    "prompt_env.sh"        # Prompt for environment variables and write .env
    "extract_keys.sh"      # Copy and extract SSH keys
    "setup_ssh_agent.sh"   # Set up SSH agent auto-load and permissions
    "clone_dotfiles.sh"    # Clone dotfiles repo to .backup (skips itself if not enabled)
    "clone_wiz.sh"         # Clone the wiz repo
)

for script_name in "${INIT_SCRIPTS[@]}"; do
    script_path="$INIT_DIR/$script_name"
    if [ -f "$script_path" ]; then
        perms=$(stat -c "%A" "$script_path")
        if [ -x "$script_path" ]; then
            echo "[DRY RUN] Would run: $script_path (permissions: $perms)"
        else
            echo "[DRY RUN] Would run: $script_path (permissions: $perms) [NOT EXECUTABLE]"
        fi
    else
        echo "[DRY RUN] Warning: $script_path not found, would skip."
    fi
    echo
done

echo "===== WIZ BOOTSTRAP DRY RUN ====="
echo



# Define and deduplicate bootstrap scripts
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

# Check for mismatches between BOOTSTRAP_SCRIPTS and actual files
actual_bootstrap_files=()
while IFS= read -r -d $'\0' file; do
    actual_bootstrap_files+=("$(basename "$file")")
done < <(find "$BOOTSTRAP_DIR" -maxdepth 1 -type f -name '*.sh' -print0)

echo "[CHECK] Scripts in BOOTSTRAP_SCRIPTS but missing in bootstrap/:"
for script_name in "${BOOTSTRAP_SCRIPTS[@]}"; do
    found=0
    for actual in "${actual_bootstrap_files[@]}"; do
        if [[ "$script_name" == "$actual" ]]; then
            found=1
            break
        fi
    done
    if [ $found -eq 0 ]; then
        echo "  - $script_name"
    fi
done

echo "[CHECK] Extra scripts in bootstrap/ not listed in BOOTSTRAP_SCRIPTS:"
for actual in "${actual_bootstrap_files[@]}"; do
    found=0
    for script_name in "${BOOTSTRAP_SCRIPTS[@]}"; do
        if [[ "$actual" == "$script_name" ]]; then
            found=1
            break
        fi
    done
    if [ $found -eq 0 ]; then
        echo "  - $actual"
    fi
done
echo

declare -A seen
for script_name in "${BOOTSTRAP_SCRIPTS[@]}"; do
    seen["$script_name"]=1
done
for script_name in "${!seen[@]}"; do
    script_path="$BOOTSTRAP_DIR/$script_name"
    if [ -f "$script_path" ]; then
        perms=$(stat -c "%A" "$script_path")
        if [ -x "$script_path" ]; then
            echo "[DRY RUN] Would run: $script_path (permissions: $perms)"
        else
            echo "[DRY RUN] Would run: $script_path (permissions: $perms) [NOT EXECUTABLE]"
        fi
    else
        echo "[DRY RUN] Warning: $script_path not found, would skip."
    fi
    echo
done

echo "===== WIZ wiz_dryrun.sh complete! ====="
echo
