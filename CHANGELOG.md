# Changelog

All notable changes to this project will be documented in this file.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/)

---

## [Unreleased]

### ✨ Features
- Mission Control UX: preflight briefing, per-module progress lines, and final
  summary screen (`show_preflight`, `show_module_header`, `show_module_result`,
  `show_launch_summary`) — display-only, no behavior change

### ♻️ Code Refactoring
- Split `common.sh` into `pkg.sh`, `download.sh`, and `ui.sh` for separation of concerns
- Moved orchestration logic from `bin/install` into `lib/module-base.sh`
- Added `wiz_download_verified`, `wiz_add_shell_block`, `wiz_update_shell_block` shared helpers
- Moved `extract_ssh_keys_from_archive` from `common.sh` to `ssh.sh`
- Added `_module_banner()` helper; all `describe_*` functions use it
- Removed dead code from `bin/install` and `common.sh`

### 🐛 Bug Fixes
- Fixed operator precedence bug in `verify_dependencies()`
- Set `NVM_INSTALLER_SHA256` for NVM v0.39.7 (was blank; blocked every fresh install)
- Renamed `show_installation_summary()` to avoid name collision with install_summary module
- Renamed shadowing `basename` locals; added nullglob guards in archive extraction
- Moved `get_cached_ssh_fingerprint()` from `common.sh` to `ssh.sh`
- Unknown CLI flags in `bin/install` now exit with code 2 instead of warn-and-continue
- Resolved all HIGH-severity audit findings

### ⚡ Performance Improvements
- Batch apt pre-check in `install_packages()` via single `dpkg-query`
- Buffered `_write_log()` via persistent file descriptor

### 🧪 Tests
- Added BATS test suite: 7 suites, 43 tests
- Fixed `run`/`bats_run` namespace collision with wiz's `run()` wrapper
- Added `_setup_isolated_home` helper to prevent tests touching real `~/.bashrc`/`~/.zshrc`
- Fixed `run_tests.sh` so `--tap`, default, and explicit-file modes all work

### 🤖 Continuous Integration
- Added BATS test workflow (`.github/workflows/test.yml`)

### 📚 Documentation
- Added deprecation notices to backward-compat variable aliases in `common.sh`
- Added `docs/RELEASE.md` pre-flight checklist
- Fixed Bash minimum version in README from 4.1+ to 4.3+
- Synced `WIZ_VERSION` to match last release tag

---

## [0.4.0] — 2024

### ✨ Features
- Added installation summary module (`install_summary.sh`) — shows tools, paths, next steps after install
- Skip descriptions for already-completed modules to reduce noise on re-runs
- SSH fingerprint caching (`get_cached_ssh_fingerprint`) for performance
- Removed redundant `apt-get update` in neovim module

### ⚡ Performance Improvements
- Batch package operations; reduced redundant apt calls
- 20–55 seconds saved per typical installation run

---

## [0.3.0] — 2024

### ✨ Features
- Swapped phase order: Phase 1 = Development Tools, Phase 2 = Identity/SSH setup
- SSH agent auto-loading fixed in `.zshrc`
- Starship prompt Nerd Font detection with automatic plain-text fallback config
- Improved initialization order and error handling

---

## [0.2.0] — 2024

### ✨ Features
- Complete architectural overhaul: `lib/` directory structure with module system
- `bin/bootstrap` (curl-pipe entry point) and `bin/install` (two-phase installer)
- `lib/module-base.sh`: module interface, dependency sort, topological install order, state management
- `lib/common.sh`: centralized logging, `run`/`run_stream` wrappers, OS detection, hooks
- Module library: `install_essentials`, `install_zsh`, `install_starship`, `install_node`, `install_bun`, `install_neovim`, `install_summary`
- Hook system: `pre-install.d/`, `post-install.d/`, `pre-module.d/`, `post-module.d/`
- Module state persistence in `~/.wiz/state/`

---

## [0.1.0] — 2024

### ✨ Features
- Initial release: modular, idempotent Bash developer environment bootstrapper for WSL/Linux
- Interactive Git identity and SSH key setup
- Automated installation of developer tools and shell enhancements
- Centralized logging, error handling, and atomic config writes
- Dotfile backup support
- User-defined post-install hooks
- Color-coded output and comprehensive error handling
