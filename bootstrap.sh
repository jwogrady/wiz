#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$SCRIPT_DIR/bootstrap"

echo
echo "===== WIZ BOOTSTRAP PHASE ====="
echo

# Collect and sort scripts
mapfile -d '' BOOTSTRAP_SCRIPTS < <(find "$BOOTSTRAP_DIR" -maxdepth 1 -type f -name "*.sh" -print0 | sort -z)

echo "Bootstrap scripts to run:"
for idx in "${!BOOTSTRAP_SCRIPTS[@]}"; do
    script_name="$(basename "${BOOTSTRAP_SCRIPTS[$idx]}")"
    printf "  %2d. %s\n" "$((idx+1))" "$script_name"
done
echo

for script_path in "${BOOTSTRAP_SCRIPTS[@]}"; do
    script_name="$(basename "$script_path")"
    if [ -f "$script_path" ]; then
        # Idempotency check for backup script
        if [[ "$script_name" == "40-backup-default-dots.sh" ]]; then
            MACHINE_NAME="$(hostname)"
            TODAY="$(date +'%Y-%m-%d')"
            if ls "$HOME/.backup/$MACHINE_NAME/${TODAY}_*" 1>/dev/null 2>&1; then
                echo "Backup for today already exists, skipping $script_name."
                continue
            fi
        fi
        echo "Running $script_name..."
        bash "$script_path"
    else
        echo "Warning: $script_name not found, skipping."
    fi
    echo
done

echo "===== WIZ bootstrap.sh complete! ====="
echo
