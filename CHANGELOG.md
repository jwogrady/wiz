# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-11-03

### 🏗️ Architecture Overhaul

Complete rewrite of Wiz with modular architecture and enhanced reliability.

**This is NOT a breaking change from v0.1.0** - All functionality is preserved or improved.
The only changes are to the installation method (now uses `bin/bootstrap` and `bin/install`
instead of `install.sh`), but the end result provides the same or better developer environment.

### ✨ Features

#### New Installation System
- **Two-phase installation workflow** - Identity setup (Phase 1) then tools installation (Phase 2) with verification prompt ([432155e](https://github.com/jwogrady/wiz/commit/432155e))
- **Curl-pipeable bootstrap** - One-command setup via `curl ... | bash` ([67bc12b](https://github.com/jwogrady/wiz/commit/67bc12b))
- **Automatic shell reload** - Applies changes immediately after installation ([1d8442d](https://github.com/jwogrady/wiz/commit/1d8442d))
- **Progress tracking** - Visual progress bars showing installation status
- **Dry-run mode** - Test installation without executing commands
- **Module selection** - Install only specific modules with `--module=name`
- **Dependency resolution** - Automatic topological sorting of module dependencies
- **State management** - Track and resume installations in `~/.wiz/state/`

#### New Modules
- **Zsh module** - Complete Oh My Zsh setup with proper configuration
- **Summary module** - Installation recap showing what was installed and next steps

#### Enhanced Modules
All modules rewritten with improved error handling and verification:
- **Essentials** - Consolidated Docker, GitHub CLI, network tools, monitoring tools (~50+ packages)
- **Node.js** - Better NVM integration with shell configuration
- **Bun** - Fixed installer with proper argument passing
- **Starship** - No Nerd Font preset for WSL compatibility, enhanced fallback installation
- **Neovim** - Integrated Lua configuration setup

### 🐛 Bug Fixes

- **Fixed installer argument passing** for starship and bun modules - Corrected bash pipe argument handling ([d028945](https://github.com/jwogrady/wiz/commit/d028945))
- **Fixed README installation workflow** - Corrected documentation to use bin/bootstrap ([91481e8](https://github.com/jwogrady/wiz/commit/91481e8))
- **Fixed starship verification hanging** - Prevented infinite wait during module verification ([c1130a6](https://github.com/jwogrady/wiz/commit/c1130a6))
- **Fixed starship config** - Always apply No Nerd Font preset for consistency ([e2d15fb](https://github.com/jwogrady/wiz/commit/e2d15fb))
- **Removed interactive prompts from bootstrap** - Made curl-pipeable installation truly non-interactive ([67bc12b](https://github.com/jwogrady/wiz/commit/67bc12b))
- **Fixed parse_args function** - Removed stray text causing syntax errors ([840bd4b](https://github.com/jwogrady/wiz/commit/840bd4b))
- **Fixed bootstrap syntax errors** - Resolved missing dependencies and shell errors ([07e6288](https://github.com/jwogrady/wiz/commit/07e6288))

### ♻️ Code Refactoring

- **Modular architecture** - Introduced `lib/module-base.sh` framework for dependency resolution
- **Separated concerns** - `bin/bootstrap` for initial setup, `bin/install` for orchestration
- **Directory restructure** - New `bin/` and `lib/` organization (was `init/`)
- **Consolidated modules** - Combined related functionality (Docker, GitHub CLI, network tools all in essentials)
- **Applied easybash coding standards** - Consistent formatting, color variables, readonly constants

### 📚 Documentation

- **Comprehensive README** - Complete rewrite with workflow diagrams and examples
- **Version history** - Detailed migration guide from v0.1.0
- **Inline documentation** - Extensive comments throughout codebase
- **Release automation** - Added Release Please for automated changelog generation

### 🔧 Infrastructure

- **Release Please** - Automated changelog and release management
- **Commitlint** - Enforce conventional commit message format
- **ShellCheck workflow** - Automated linting of bash scripts (replaces standalone installation)

### 📦 Functionality Mapping (v0.1.0 → v0.2.0)

**No core functionality lost.** All tools from v0.1.0 are still installed:

| v0.1.0 Module | v0.2.0 Location | Notes |
|---------------|-----------------|-------|
| install_essentials | ✅ `lib/modules/install_essentials.sh` | Enhanced with more packages |
| install_docker | ✅ `lib/modules/install_essentials.sh` | Consolidated into essentials |
| install_github_cli | ✅ `lib/modules/install_essentials.sh` | Consolidated into essentials |
| install_hostmaster_tools | ✅ `lib/modules/install_essentials.sh` | All network tools included |
| install_system_specs_tools | ✅ `lib/modules/install_essentials.sh` | All monitoring tools included |
| install_node | ✅ `lib/modules/install_node.sh` | Enhanced with better NVM setup |
| install_bun | ✅ `lib/modules/install_bun.sh` | Fixed and enhanced |
| install_neovim | ✅ `lib/modules/install_neovim.sh` | Enhanced with Lua config |
| install_neovim_config | ✅ `lib/modules/install_neovim.sh` | Integrated into neovim module |
| install_starship_zsh | ✅ `lib/modules/install_starship.sh` | Enhanced with fallback options |

**Intentionally removed (non-essential):**
- `install_openai_cli.sh` - Niche tool, not core to dev environment
- `install_shellcheck.sh` - Standalone install removed (ShellCheck now in CI workflows)

### 📈 Statistics

- 36 files changed
- 4,090 lines added
- 1,190 lines removed
- Net improvement: +2,900 lines of enhanced, documented code

### 🚀 Migration from v0.1.0

v0.2.0 is a fresh installation approach with the same end result:

**Installation method changed:**
- **Old:** `curl ... install.sh | bash` then `cd ~/wiz/init && ./bootstrap.sh`
- **New:** `curl ... bin/bootstrap | bash` (single command, interactive prompt for Phase 2)

**All tools still installed:**
- ✅ Docker and Docker Compose
- ✅ GitHub CLI (gh)
- ✅ Node.js via NVM
- ✅ Bun runtime
- ✅ Neovim with configuration
- ✅ Starship prompt
- ✅ All network utilities (nmap, mtr, dnsutils, etc.)
- ✅ All monitoring tools (htop, btop, neofetch, glances)
- ✅ Build tools and development essentials

**If upgrading:**
- Backup `~/.wiz/` directory
- New state management won't conflict with existing installations
- Safe to run - all modules are idempotent

---

## [0.1.0] - 2025-10-XX

### Initial Release

First release of Wiz - Terminal Magic

### Features

- Basic modular installer with `install.sh` entry point
- Individual module scripts in `init/modules/`
- Simple sequential installation
- Git identity and SSH key setup
- Module installations:
  - Docker and Docker Compose
  - Node.js via NVM
  - Bun JavaScript runtime
  - Neovim text editor
  - GitHub CLI
  - ShellCheck (standalone)
  - Starship prompt
  - System monitoring tools
  - Network utilities
  - OpenAI CLI

### Installation Method

Two-step process:
1. `curl ... install.sh | bash` - Clone repo and setup identity
2. `cd ~/wiz/init && ./bootstrap.sh` - Install all modules

---

[0.2.0]: https://github.com/jwogrady/wiz/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/jwogrady/wiz/releases/tag/v0.1.0

