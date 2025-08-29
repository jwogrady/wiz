#!/usr/bin/env bash
set -euo pipefail

install_nvm_and_node() {
  echo "→ Installing NVM + Node (LTS)…"

  # Prereqs (Ubuntu/WSL safe)
  if command -v apt >/dev/null 2>&1; then
    sudo apt update -y
    sudo apt install -y curl ca-certificates build-essential
  fi

  # Install NVM if missing
  if [ ! -d "$HOME/.nvm" ]; then
    echo "→ NVM not found, installing…"
    if command -v curl >/dev/null 2>&1; then
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    else
      wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
  else
    echo "✓ NVM already installed."
  fi

  # Load NVM safely (disable nounset just for this block)
  export NVM_DIR="$HOME/.nvm"
  set +u
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  set -u

  # Add NVM init to rc files (idempotent with block markers)
  add_nvm_to_shell_rc "$HOME/.bashrc"
  add_nvm_to_shell_rc "$HOME/.zshrc"

  # Install or update Node LTS
  if ! command -v node >/dev/null 2>&1; then
    echo "→ Installing Node LTS…"
    nvm install --lts
  else
    echo "→ Updating to latest LTS…"
    nvm install --lts
    nvm alias default 'lts/*'
  fi

  # Use LTS now
  nvm use --lts

  # Verify
  echo "Node: $(node -v)"
  echo "npm:  $(npm -v)"

  # Enable Corepack for Yarn & pnpm
  if command -v corepack >/dev/null 2>&1; then
    corepack enable || true
  fi

  npm set fund false audit false audit-level=moderate loglevel=warn

  echo "✓ NVM/Node/npm ready."
}

add_nvm_to_shell_rc() {
  local rc="$1"
  [ -e "$rc" ] || return 0

  # Only insert if block markers not present
  if ! grep -q '# >>> NVM init >>>' "$rc"; then
    cat >> "$rc" <<'EOF'

# >>> NVM init >>>
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
# <<< NVM init <<<
EOF
    echo "✓ Added NVM init block to $rc"
  else
    echo "✓ NVM init already present in $rc"
  fi
}

# --- run it ---
install_nvm_and_node
