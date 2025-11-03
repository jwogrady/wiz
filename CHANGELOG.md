# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-11-03

### ✨ Features

- Implemented two-phase installation workflow with verification prompt
- Automatic shell reload after installation completes
- Curl-pipeable bootstrap script for one-command setup
- Progress bars and enhanced visual output
- Comprehensive logging to logs/ directory
- Dry-run mode for testing
- Module-specific skip/select options
- Dependency graph visualization (--graph)

### 🐛 Bug Fixes

- Corrected installer argument passing for starship and bun modules
- Fixed README installation workflow (bootstrap vs install)
- Fixed starship verification process hanging
- Removed interactive prompts from curl-piped bootstrap
- Improved phase completion messaging
- Enhanced error handling and recovery mechanisms
- Applied easybash coding style standards throughout
- Removed stray text from parse_args function

### ♻️ Code Refactoring

- Complete architectural overhaul with modular framework
- Introduced lib/module-base.sh for dependency resolution
- Separated bootstrap (bin/bootstrap) from installer (bin/install)
- Implemented state management system in ~/.wiz/state/
- Rewritten all 7 modules with self-contained logic

### 📚 Documentation

- Comprehensive README update with detailed workflow diagrams
- Added version history and migration guide
- Improved inline documentation throughout codebase
- Added command-line options reference

### 🔧 Miscellaneous Chores

- Applied consistent color variable naming (COLOR_ prefix)
- Proper array formatting (4-space indent, 5 values/line)
- Heredoc formatting (uppercase EOF, space after <<)
- Readonly constants for configuration
- Idempotent design - safe to run multiple times

### ⚠️ BREAKING CHANGES

- Complete rewrite - not compatible with v0.1.0
- New directory structure: bin/ and lib/ instead of init/
- Different CLI interface
- Removed deprecated modules (hostmaster-tools, openai-cli, etc.)

## [0.1.0] - 2025-10-XX

### ✨ Features

- Initial release of Wiz - Terminal Magic
- Basic modular installer with install.sh entry point
- Individual module scripts in init/modules/
- Simple sequential installation
- Git identity and SSH key setup
- Docker, Node.js, Neovim, GitHub CLI installation
- Automated backup of user dotfiles
- Color-coded output and error handling

[0.2.0]: https://github.com/jwogrady/wiz/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/jwogrady/wiz/releases/tag/v0.1.0
