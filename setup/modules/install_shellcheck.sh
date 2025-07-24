#!/usr/bin/env bash
# Install ShellCheck from source

# Check for required commands before proceeding
for cmd in git cabal; do
	if ! command -v "$cmd" &>/dev/null; then
		error "Required command not found: $cmd"
		exit 1
	fi
done


# Ensure $HOME/code directory exists before cloning
if [ ! -d "$HOME/code" ]; then
	mkdir -p "$HOME/code"
	log "Created directory $HOME/code."
fi

# Only clone and build ShellCheck if not already installed in $HOME/.local/bin
if [ ! -x "$HOME/.local/bin/shellcheck" ]; then
	SHELLCHECK_SRC="$HOME/code/shellcheck"
	prepare_code_repo "$SHELLCHECK_SRC"
	log "Cloning ShellCheck source into $SHELLCHECK_SRC..."
	run "git clone --depth 1 https://github.com/koalaman/shellcheck.git '$SHELLCHECK_SRC'"
	run "sudo apt-get update"
	for pkg in git xz-utils cabal-install; do
		if dpkg -s "$pkg" &>/dev/null; then
			log "$pkg is already installed. Skipping."
		else
			run "sudo apt-get install -y $pkg"
		fi
	done
	if [ -d "$SHELLCHECK_SRC" ]; then
		cd "$SHELLCHECK_SRC" || exit 1
	else
		error "ShellCheck source directory not found: $SHELLCHECK_SRC"
		exit 1
	fi
	run "cabal update"
	run "cabal install --installdir=\"$HOME/.local/bin\" --install-method=copy --overwrite-policy=always"
	log "ShellCheck version: $("$HOME"/.local/bin/shellcheck --version | head -n 1)"
	cd "$HOME" || exit
	run "rm -rf '$SHELLCHECK_SRC'"
else
	log "ShellCheck binary already exists at $HOME/.local/bin/shellcheck."
	echo -n "ShellCheck is already installed in $HOME/.local/bin. Reinstall? (y/N, auto-skip in 10s): "
	read -t 10 REPLY
	if [[ "$REPLY" =~ ^[Yy]$ ]]; then
		SHELLCHECK_SRC="$HOME/code/shellcheck"
		prepare_code_repo "$SHELLCHECK_SRC"
		log "Cloning ShellCheck source into $SHELLCHECK_SRC..."
		run "git clone --depth 1 https://github.com/koalaman/shellcheck.git '$SHELLCHECK_SRC'"
		run "sudo apt-get update"
		for pkg in git xz-utils cabal-install; do
			if dpkg -s "$pkg" &>/dev/null; then
				log "$pkg is already installed. Skipping."
			else
				run "sudo apt-get install -y $pkg"
			fi
		done
		if [ -d "$SHELLCHECK_SRC" ]; then
			cd "$SHELLCHECK_SRC" || exit 1
		else
			error "ShellCheck source directory not found: $SHELLCHECK_SRC"
			exit 1
		fi
		run "cabal update"
		run "cabal install --installdir=\"$HOME/.local/bin\" --install-method=copy --overwrite-policy=always"
		log "ShellCheck version: $("$HOME"/.local/bin/shellcheck --version | head -n 1)"
		cd "$HOME" || exit
		run "rm -rf '$SHELLCHECK_SRC'"
	else
		log "Skipping ShellCheck reinstall."
	fi
fi
