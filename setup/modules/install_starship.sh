#!/usr/bin/env bash
# 🌌 Cosmic Strip Club Neon Installer — You're glowing, babe

set -euo pipefail

log() { printf "\033[1;35m[✦] %s\033[0m\n" "$1"; }

append_once() {
  # append_once <file> <exact_line>
  local file="$1" line="$2"
  touch "$file"
  if ! grep -Fqx "$line" "$file"; then
    printf "%s\n" "$line" >> "$file"
    log "✅ Added to $(basename "$file"): $line"
  else
    log "✅ Already present in $(basename "$file")"
  fi
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    log "Starship already installed: $(command -v starship)"
    return
  fi
  if command -v brew >/dev/null 2>&1; then
    log "Installing Starship via Homebrew…"
    brew install starship
  elif command -v apt-get >/dev/null 2>&1; then
    log "Installing Starship via apt…"
    sudo apt-get update -y
    sudo apt-get install -y starship
  else
    log "Installing Starship via official script…"
    curl -fsSL https://starship.rs/install.sh | bash -s -- -y
  fi
}

log "Installing Starship (cross-shell prompt)…"
install_starship

log "Adding Starship init to ~/.zshrc and ~/.bashrc if not present…"
append_once "$HOME/.zshrc" 'eval "$(starship init zsh)"'
append_once "$HOME/.bashrc" 'eval "$(starship init bash)"'

log "Creating Starship config directory at ~/.config if it doesn't exist…"
mkdir -p "$HOME/.config"

log "Writing cosmic strip club neon starship.toml…"
cat > "$HOME/.config/starship.toml" <<'EOF'
# ~/.config/starship.toml
# 🌌 Cosmic Strip Club Neon — You're glowing, babe

format = """
$directory$git_branch$git_status$package
$nodejs$rust$python
$container$docker_context
$time$character
"""

[character]
success_symbol = "[➤](bold fg:#ff69b4)"  # hot pink
error_symbol = "[✖](bold fg:#ff1493)"    # deep pink
vimcmd_symbol = "[](bold fg:#da70d6)"   # orchid purple
format = "$symbol "

[directory]
style = "fg:#ee82ee bold"  # violet
truncation_length = 3
truncation_symbol = "💋/"

[git_branch]
symbol = " "
style = "fg:#ff00ff bold"  # magenta madness

[git_status]
style = "fg:#db7093"  # pale violet red

[package]
symbol = "🎁 "
style = "fg:#ff6fff"  # cotton candy neon

[nodejs]
symbol = "🟢 "
style = "fg:#00ffff"  # cyan glow

[python]
symbol = "🐍 "
style = "fg:#da70d6"  # orchid
format = "[$symbol$version]($style) "

[rust]
symbol = "🦀 "
style = "fg:#ff1493"  # hot pink crab energy

[docker_context]
symbol = "🐳 "
style = "fg:#00bfff"  # neon ocean blue

[container]
# IMPORTANT: use a TOML literal string to avoid invalid escapes
format = '[$symbol \($name\)](fg:#ff00ff italic) '

[time]
disabled = false
format = "[🕒 $time](fg:#db70ff bold)"
time_format = "%H:%M:%S"

[cmd_duration]
format = "⏱ [$duration](bold fg:#ff69b4)"
min_time = 300

[battery]
format = "[🔋$percentage]($style) "
full_symbol = "💖"
charging_symbol = "⚡"
discharging_symbol = "💔"

[battery.display]
threshold = 30
style = "bold fg:#ff1493"

[shell]
zsh_indicator = "💅"
style = "bold fg:#ff69b4"
EOF

log "Validating starship config…"
if ! starship explain >/dev/null 2>&1; then
  log "❌ Starship config failed to parse. Check ~/.config/starship.toml"
  exit 1
fi

log "✨ Starship config installed successfully."
log "Reload your shell or run: source ~/.zshrc (zsh) / source ~/.bashrc (bash)"
