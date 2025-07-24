# PROMPT.md — AI System/Developer Guide for Wiz

## Project Overview
Wiz is a modular, idempotent, and extensible Bash-based developer environment bootstrapper for WSL/Unix systems. It automates the setup of a complete development environment, including identity, SSH keys, editors, shells, and popular tools, using a clean, maintainable, and testable script structure. All scripts are designed for clarity, safety, and repeatability.

## System Goals
- **Automate**: Remove manual steps from onboarding a new dev machine.
- **Idempotent**: Safe to re-run any time; scripts check and skip already-completed steps.
- **Extensible**: Add new modules or hooks without changing the core logic.
- **Maintainable**: Centralized logging, error handling, and utilities.
- **User-Friendly**: Clear, color-coded output and minimal prompts.

## Key Components
- `install.sh`: Interactive entry point for identity, SSH, and repo setup. Handles `.env`, SSH keys, and global git config.
- `setup/bootstrap.sh`: Orchestrates all module installs, sources aliases, and runs post-install hooks.
- `setup/modules/`: One script per tool/stack (e.g., Neovim, Node, Docker, ShellCheck, etc.). Each is self-contained and idempotent.
- `setup/lib/common.sh`: Shared logging, error handling, and utility functions.
- `setup/aliases.sh`: User shell aliases.
- `setup/hooks/post_install_custom.sh`: Optional user-defined post-install steps.
- `setup/tests/`: Automated tests for utilities and idempotency.
- `.github/workflows/`: CI for ShellCheck and commit message linting.

## Script Flow
1. **install.sh**
    - Prompts for Git identity, email, GitHub username, and (optionally) Windows username.
    - Handles `.env` creation/validation and SSH key extraction.
    - Sets up global `.gitconfig` and `.gitignore_global`.
    - Ensures `ssh-agent` is running and persistent.
    - Clones the Wiz repo if not present.
    - Optionally cleans up install artifacts.
    - Instructs user to run `setup/bootstrap.sh` next.

2. **setup/bootstrap.sh**
    - Sources `setup/lib/common.sh` for logging/utilities.
    - Iterates over a list of module scripts in `setup/modules/`, sourcing each if present.
    - Sources `setup/aliases.sh` for user aliases.
    - Sources `setup/hooks/post_install_custom.sh` if present.
    - Prints next steps and completion message.

3. **Module Scripts**
    - Each `install_*.sh` script is self-contained, idempotent, and uses `log` and `run` from `common.sh`.
    - Modules check for existing installs and skip or update as needed.
    - All output is color-coded and consistent.

4. **Utilities**
    - `log`, `warn`, `error`, and `run` functions are defined in `common.sh` and used everywhere for consistency and dry-run support.

5. **Testing & CI**
    - `setup/tests/` contains scripts to test idempotency and utility functions.
    - GitHub Actions run ShellCheck and commit message linting on PRs and pushes.

## AI/Developer Usage
- **To add a new tool:** Create a new `install_<tool>.sh` in `setup/modules/`, following the style and idempotency of existing modules.
- **To add a post-install step:** Add commands to `setup/hooks/post_install_custom.sh`.
- **To update logging or error handling:** Edit `setup/lib/common.sh`.
- **To test:** Add or update scripts in `setup/tests/`.
- **To run end-to-end:**
    1. Run `install.sh` from the repo root.
    2. Run `setup/bootstrap.sh` from the `setup/` directory.

## Conventions
- All scripts use `#!/usr/bin/env bash` and `set -euo pipefail` for safety.
- All user-facing output is color-coded and prefixed with `[INFO]`, `[WARN]`, or `[ERROR]`.
- All modules are sourced, not executed, to share environment and functions.
- All paths are relative to the `setup/` directory for consistency.
- All scripts are safe for repeated use (idempotent).

## Example Module (install_neovim.sh)
```bash
#!/usr/bin/env bash
# Install Neovim and AstroNvim config
log "Cloning and installing latest Neovim..."
if [ ! -d "$HOME/neovim" ]; then
    run "git clone https://github.com/neovim/neovim.git $HOME/neovim"
else
    log "Neovim source already exists at $HOME/neovim, skipping clone."
fi
cd "$HOME/neovim" || exit
run "make CMAKE_BUILD_TYPE=Release"
run "sudo make install"
log "Setting up AstroNvim (Neovim config)..."
if [ ! -d "$HOME/.config/nvim" ]; then
    run "git clone --depth 1 https://github.com/AstroNvim/AstroNvim $HOME/.config/nvim"
else
    log "AstroNvim config already exists at $HOME/.config/nvim, skipping clone."
fi
```

## Troubleshooting
- If a module fails, fix the issue and re-run `setup/bootstrap.sh`.
- If a tool is already installed, modules will skip or update as needed.
- All errors are logged and surfaced to the user.

## License
MIT License. See [LICENSE](../LICENSE) for details.

---
This file is intended for both AI agents and human developers to understand, extend, and maintain the Wiz project with best practices and minimal onboarding friction.
