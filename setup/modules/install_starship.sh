#!/usr/bin/env bash

# 🌌 Cosmic Strip Club Neon Installer — You're glowing, babe

set -e

log() {
  echo -e "\033[1;35m[✦] $1\033[0m"
}

run() {
  log "$1"
  eval "$1"
}

log "Installing Starship (cross-shell prompt)..."
run "curl -fsSL https://starship.rs/install.sh | bash -s -- -y"

log "Adding Starship init to ~/.zshrc if not present..."
if ! grep -q "eval \"\$(starship init zsh)\"" "$HOME/.zshrc" 2>/dev/null; then
  echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
  log "✅ Starship init line added to ~/.zshrc"
else
  log "✅ Starship already initialized in ~/.zshrc"
fi

log "Creating Starship config directory at ~/.config if it doesn't exist..."
mkdir -p "$HOME/.config"

log "Writing cosmic strip club neon starship.toml..."
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
format = "[$symbol \($name\)](fg:#ff00ff italic) "

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

log "✨ Starship config installed successfully."
log "Reload your shell or run: source ~/.zshrc"
