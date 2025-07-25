# --- Main execution loop ---
main() {
	show_banner
	log "Starting devbox bootstrap..."

	SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
	MODULES_DIR="$SCRIPT_DIR/modules"

	# List modules to disable (just the base name, without .sh)
	DISABLED_MODULES=(

	)

	# Source aliases if present
	ALIASES_FILE="$SCRIPT_DIR/aliases.sh"
	if [[ -f "$ALIASES_FILE" ]]; then
		. "$ALIASES_FILE"
		log "Sourced aliases from $ALIASES_FILE"
	fi

	# Define the desired installation order (without .sh)
	MODULES_ORDER=(
		install_essentials      # Core system tools and dependencies
		install_zsh             # Shell setup (before Starship)
		install_starship        # Prompt (after Zsh)
		install_bun             # Bun (alternative JS runtime, optional/disabled)
		install_neovim          # Neovim + AstroNvim config (after language tools)
		# add more modules as needed, in order
		summary_module          # Always runs last: prints system/install summary, next steps, aliases
	)

	# Helper: check if a module is disabled
	is_disabled() {
		local mod="$1"
		for disabled in "${DISABLED_MODULES[@]}"; do
			[[ "$mod" == "$disabled" ]] && return 0
		done
		return 1
	}

	for module in "${MODULES_ORDER[@]}"; do
		module_path="$MODULES_DIR/$module.sh"
		[[ ! -f "$module_path" ]] && continue
		if is_disabled "$module"; then
			log "Skipping disabled module: $module"
			continue
		fi
		log "Running module: $module"
		(
			. "$module_path"
		) || warn "Module failed: $module_path (see install.log for details)"
	done

}  # End of main

main  #
