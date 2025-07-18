#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_DIR="$SCRIPT_DIR/init"

echo
echo "===== WIZ INIT PHASE ====="
echo

# Collect and sort scripts
mapfile -d '' INIT_SCRIPTS < <(find "$INIT_DIR" -maxdepth 1 -type f -name "*.sh" -print0 | sort -z)

echo "Init scripts to run:"
for idx in "${!INIT_SCRIPTS[@]}"; do
    script_name="$(basename "${INIT_SCRIPTS[$idx]}")"
    printf "  %2d. %s\n" "$((idx+1))" "$script_name"
done
echo

for script_path in "${INIT_SCRIPTS[@]}"; do
    script_name="$(basename "$script_path")"
    if [ -f "$script_path" ]; then
        echo "Running $script_name..."
        bash "$script_path"
    else
        echo "Warning: $script_name not found, skipping."
    fi
    echo
done

echo "===== WIZ init.sh complete! ====="
echo
