
#!/usr/bin/env bash
# Color codes
CYAN='\033[0;36m'
# ------------------------------------------------------------------------------
# WIZ Terminal Magic
# Automated WSL/Unix developer environment setup by @jwogrady
# ------------------------------------------------------------------------------

if [ -z "$BASH_VERSION" ]; then
	echo "❌ Please run this script with bash, not sh."
	exit 1
fi

# --- Ensure running from wiz/setup directory ---
if [[ ! -f "./bootstrap.sh" || ! -d "./modules" || ! -d "./lib" ]]; then
	echo "[ERROR] Please run this script from inside the 'wiz/setup' directory (cd ~/wiz/setup)."
	exit 1
fi


# Set up logging to install.log
LOG_FILE="install.log"
exec > >(tee -a "$LOG_FILE") 2>&1


# Source common utilities
# shellcheck source=./lib/common.sh
. ./lib/common.sh

# --- Globals and Argument Parsing ---
# shellcheck disable=SC2034
export DRY_RUN=0 # Used externally in sourced scripts
for arg in "$@"; do
	case "$arg" in
	--dry-run) DRY_RUN=1 ;;
	--help)
		echo -e "\nUsage: $0 [options]"
		echo -e "  --dry-run         Show commands without executing"
		echo -e "  --help            Show this help message"
		exit 0
		;;
	*)
		warn "Unknown argument: $arg"
		exit 1
		;;
	esac
done


# --- Banner ---
show_banner() {
	echo "------------------------------------------------------------"
	echo "   COSMIC WIZ DEVBOX BOOTSTRAP v2.0"
	echo "   Automated WSL/Unix developer environment setup"
	echo "   by @jwogrady"
	echo "------------------------------------------------------------"
}


# --- User local bin path: Ensure ~/.local/bin is in PATH ---
setup_local_bin() {
	log "Adding ~/.local/bin to PATH..."
	mkdir -p "$HOME/.local/bin"
	if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$HOME/.bashrc"; then
		echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >>"$HOME/.bashrc"
	fi
	export PATH="$HOME/.local/bin:$PATH"
}


# --- Pretty print all aliases ---
print_aliases() {
	if [ -f "./aliases.sh" ]; then
		echo "------------------------------------------------------------"
		echo "   Available Aliases"
		echo "------------------------------------------------------------"
		grep -E "^alias " ./aliases.sh | sed -E "s/^alias ([^=]+)='([^']+)'$/\1 \t→ \2/" | column -t -s $'\t'
		echo "------------------------------------------------------------"
	else
		echo "No aliases.sh file found."
	fi
}

# --- Main execution loop ---
main() {
	show_banner
	log "Starting devbox bootstrap..."

	# Orchestrate all modules
	SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
	for module in \
		install_essentials \
		install_shellcheck \
		install_neovim \
		install_hostmaster_tools \
		install_system_specs_tools \
		install_node \
		install_bun \
		install_zsh \
		install_openai_cli \
		install_github_cli; do
		MODULE_PATH="$SCRIPT_DIR/modules/${module}.sh"
		if [[ -f "$MODULE_PATH" ]]; then
			log "Running module: $module"
			# shellcheck source=/dev/null
			(
				. "$MODULE_PATH"
			) || warn "Module failed: $MODULE_PATH (see install.log for details)"
		else
			warn "Module not found: $MODULE_PATH"
		fi
	done

	# Source aliases for current shell (Bash or Zsh)
	ALIASES_FILE="./aliases.sh"
	if [ -f "$ALIASES_FILE" ]; then
		log "Sourcing aliases from init directory..."
		# shellcheck source=/dev/null
		case "$SHELL" in
			*/zsh)
				source "$ALIASES_FILE";;
			*/bash)
				. "$ALIASES_FILE";;
			*)
				. "$ALIASES_FILE";;
		esac
	else
		warn "Aliases file not found at $ALIASES_FILE."
	fi

	# Source post-install hook if present
	POST_HOOK="./hooks/post_install_custom.sh"
	if [ -f "$POST_HOOK" ]; then
		log "Running post-install custom hook..."
		# shellcheck source=/dev/null
		. "$POST_HOOK"
	fi

	log "\n✅ All developer tools and environment setup complete!"
	echo -e "\n${CYAN}Next steps:${NC}"
	echo "- Review ~/.bashrc and ~/.zshrc for new settings."
	echo "- Restart your shell or run 'exec zsh' to use Zsh and Starship."
	echo "- Use the backup script for safe system snapshots."
	echo "- Happy coding!"

	print_aliases

	# Display system specs using neofetch
	log "System specs (neofetch):"
	neofetch || echo "neofetch not found"
	# Display hardware summary using lshw
	log "Hardware summary (lshw -short):"
	sudo lshw -short || echo "lshw not found"
}

# Run main loop
main "$@"
