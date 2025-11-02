#!/usr/bin/env bash

# --- System summary ---
echo "==================== System Summary ===================="
echo "User:        $USER"
echo "Hostname:    $(hostname)"
echo "OS:          $(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d= -f2- | tr -d '\"')"
echo "Kernel:      $(uname -r)"
echo "Shell:       $SHELL"
echo "Home:        $HOME"
echo "========================================================"

# --- Install summary ---
echo "==================== Install Summary ==================="
if [[ -n "${MODULES_ORDER[*]}" ]]; then
  for module in "${MODULES_ORDER[@]}"; do
    if declare -f is_disabled &>/dev/null && is_disabled "$module"; then
      echo "❌ $module (disabled)"
    else
      echo "✅ $module"
    fi
  done
fi
echo "========================================================"

# --- Next steps recap ---
echo "==================== Next Steps ========================"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Review ~/.zshrc and ~/.config/starship.toml for customizations."
echo "3. Check Neovim config at ~/.config/nvim"
echo "4. Use 'docker', 'bun', 'gh', etc. as needed."
echo "5. Explore available aliases below."
echo "========================================================"

# --- Print aliases in organized list ---
ALIASES_FILE="$SCRIPT_DIR/aliases.sh"
if [[ -f "$ALIASES_FILE" ]]; then
  echo "==================== Aliases ==========================="
  grep -E '^alias ' "$ALIASES_FILE" | sed -E "s/^alias ([^=]+)='([^']+)'$/\1: \2/" | sort
  echo "========================================================"
else
  echo "No aliases file found"
fi