# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.1](https://github.com/jwogrady/wiz/compare/v0.3.0...v0.3.1) (2025-11-04)


### Bug Fixes

* resolve shellcheck warnings (SC2034, SC2155, SC1091) ([c99ab96](https://github.com/jwogrady/wiz/commit/c99ab962f6e6938ba4088c67d3f6f8d94b0e7fa5))

## [0.3.1] - 2025-11-04

### Security
- **Removed committed install logs** - Deleted sensitive log files from repository
- **Enhanced .gitignore** - Added explicit exclusion of `*.log` files under `/logs/` directory

### Changed
- **Improved logging policy** - Installation logs are now local-only and never committed
- **Optimized module execution** - Removed redundant `is_module_complete` checks in `execute_module()` (already checked in wrapper)
- **Enhanced log truncation** - Improved log truncation for dry-run and debug modes to prevent log bloat

### Performance
- **Minor performance optimizations** - Reduced redundant dependency checks and module state queries
- **Improved idempotency** - Rerunning install produces no changes when system state is consistent

### Fixed
- **Safer dry-run handling** - Log truncation prevents excessive log file growth during dry-run operations
- **Better error handling** - More robust error handling in module execution paths

## [0.2.0] - 2025-11-03

### Added
- **Architecture Overhaul**:
  - Complete rewrite with modular architecture using `lib/module-base.sh`
  - Separated concerns: `bin/bootstrap` for initial setup, `bin/install` for orchestration
  - Introduced two-phase installation workflow (Identity → Tools)
  - Added topological dependency resolution for modules
  - Implemented state management system in `~/.wiz/state/`

- **New Modules** (7 total, all self-contained):
  - `essentials` - Core system packages (~50+ tools)
  - `zsh` - Oh My Zsh with proper configuration
  - `starship` - Cross-shell prompt with No Nerd Font preset
  - `node` - Node.js LTS via NVM with shell integration
  - `bun` - JavaScript runtime and package manager
  - `neovim` - Editor with Lua configuration
  - `summary` - Installation summary and next steps

- **Enhanced Features**:
  - Curl-pipeable bootstrap script for one-command setup
  - Interactive Phase 2 prompt with verification
  - Automatic shell reload after installation
  - Progress bars and improved visual output
  - Comprehensive logging to `logs/` directory
  - Dry-run mode for testing without executing
  - Module-specific skip/select options
  - Dependency graph visualization

### Fixed
- Fixed installer argument passing for starship and bun (bash pipe issues)
- Corrected README installation workflow (bootstrap vs install)
- Fixed starship verification hanging
- Removed interactive prompts from curl-piped bootstrap
- Improved phase completion messaging
- Enhanced error handling and recovery

### Changed
- Applied easybash coding style guide standards
- Consistent color variable naming (COLOR_ prefix)
- Proper array and heredoc formatting
- Readonly constants for configuration
- Comprehensive inline documentation
- Idempotent design - safe to run multiple times

### Removed
- Removed old `install.sh` and `init/bootstrap.sh` structure
- Removed individual module scripts in `init/modules/`
- Removed deprecated tools (hostmaster-tools, openai-cli, shellcheck standalone)
- New directory structure: `bin/` and `lib/` instead of `init/`

### Migration Notes
- v0.2.0 is a fresh install - not an in-place upgrade
- Backup your existing `~/.wiz/` directory if upgrading
- New modules will respect existing configurations
- State management allows resuming failed installations

## [0.1.0] - 2025-10-XX

### Added
- Initial release
- Basic modular installer with `install.sh` entry point
- Individual module scripts in `init/modules/`
- Simple sequential installation
- Git identity and SSH key setup
- Docker, Node.js, Neovim, GitHub CLI installation

[0.3.1]: https://github.com/jwogrady/wiz/compare/v0.2.0...v0.3.1
[0.2.0]: https://github.com/jwogrady/wiz/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/jwogrady/wiz/releases/tag/v0.1.0
