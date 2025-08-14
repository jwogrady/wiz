#!/usr/bin/env bash
set -euo pipefail

# -------- optional: source shared helpers if your driver provides them --------
if [[ -f "${BASH_SOURCE[0]%/*}/../lib.sh" ]]; then
  # shellcheck source=/dev/null
  source "${BASH_SOURCE[0]%/*}/../lib.sh"
fi

# -------- local helpers (used if lib.sh didn't define them) --------
type log >/dev/null 2>&1 || log() { printf "\033[1;36m[INSTALL]\033[0m %s\n" "$*"; }
type run >/dev/null 2>&1 || run() { log "$*"; eval "$@"; }

# Detect WSL
is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }

# Ensure ~/.zshrc exists before grepping/appending
ZSHRC="${HOME}/.zshrc"
[[ -f "$ZSHRC" ]] || : >"$ZSHRC"

# -------- install zsh if missing --------
log "Installing zsh..."
if ! dpkg -s zsh &>/dev/null; then
  run "sudo apt-get update -y"
  run "sudo apt-get install -y zsh"
else
  log "zsh already installed. Skipping."
fi

# -------- append SSH agent + Starship guards (idempotent) --------
if ! grep -q 'COSMIC WIZ SSH AGENT' "$ZSHRC" 2>/dev/null; then
  log "Updating $ZSHRC with SSH agent + Starship guards..."
  cat <<'EOF' >>"$ZSHRC"

# --- COSMIC WIZ SSH AGENT ---
# Only for interactive shells so batch jobs don't spawn agents.
case $- in
  *i*)
    if [ -z "${SSH_AUTH_SOCK:-}" ] || ! ssh-add -l >/dev/null 2>&1; then
      eval "$(ssh-agent -s)"
      ssh-add "$HOME/.ssh/id_jwogrady" 2>/dev/null || true
      ssh-add "$HOME/.ssh/id_vultr"    2>/dev/null || true
    fi
  ;;
esac

# Starship: init for the shell you're actually in (safe if mis-sourced)
if [ -n "$ZSH_VERSION" ]; then
  eval "$(starship init zsh)"
elif [ -n "$BASH_VERSION" ]; then
  eval "$(starship init bash)"
fi
EOF
else
  log "$ZSHRC already contains SSH agent block. Skipping."
fi

# -------- set default shell or apply WSL-friendly fallback --------
ZSH_PATH="$(command -v zsh || true)"
if [[ -z "${ZSH_PATH:-}" ]]; then
  log "zsh not found after install. Aborting."
  exit 1
fi

log "Attempting to set default shell to: $ZSH_PATH"
if is_wsl; then
  log "WSL detected; skipping chsh/usermod. Applying ~/.bashrc auto-switch."
  if ! grep -q 'exec zsh # auto-switch' "$HOME/.bashrc" 2>/dev/null; then
    cat <<'EOS' >>"$HOME/.bashrc"

# auto-switch to zsh if interactive
if [ -t 1 ] && command -v zsh >/dev/null 2>&1; then
  exec zsh # auto-switch
fi
EOS
  fi
else
  # Try chsh first (may prompt; show output so it doesn't look hung)
  if chsh -s "$ZSH_PATH" "$USER"; then
    log "Default shell updated with chsh."
  # Then try sudo usermod without prompting (skip if it would prompt)
  elif sudo -n true 2>/dev/null && sudo usermod -s "$ZSH_PATH" "$USER"; then
    log "Default shell updated with sudo usermod (non-interactive)."
  else
    log "Could not change default shell. Falling back to ~/.bashrc auto-switch."
    if ! grep -q 'exec zsh # auto-switch' "$HOME/.bashrc" 2>/dev/null; then
      cat <<'EOS' >>"$HOME/.bashrc"

# auto-switch to zsh if interactive
if [ -t 1 ] && command -v zsh >/dev/null 2>&1; then
  exec zsh # auto-switch
fi
EOS
    fi
  fi
fi

log "Done. Open a new terminal or run: exec bash -l  (you'll drop into zsh automatically)."
