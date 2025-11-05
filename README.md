# 🌌 Wiz - Terminal Magic

> **Modular Developer Environment Bootstrapper**

Wiz is a comprehensive, modular installation system for setting up a complete development environment on Linux and WSL. It handles everything from Git identity configuration and SSH key management to installing essential development tools, shell configurations, and runtime environments.

[![Version](https://img.shields.io/badge/version-0.4.0-blue.svg)](https://github.com/jwogrady/wiz/releases)

---

## ✨ Features

### 🎯 **Two-Phase Installation**

**Phase 1: Development Tools**
- Essential system packages (~50+ tools)
- Zsh shell with Oh My Zsh framework
- Starship cross-shell prompt with custom theme
- Node.js LTS via NVM
- Bun JavaScript runtime
- Neovim editor

**Phase 2: Identity & SSH Setup**
- Interactive Git identity configuration (name, email, GitHub username)
- SSH key import from Windows or archive files
- SSH agent configuration and key management
- Global Git configuration and `.gitignore` setup

### 🏗️ **Single Script Architecture**

- **Self-contained**: Everything in one script for simplicity
- **Idempotent**: Safe to run multiple times
- **Dry-run support**: Preview changes before applying
- **Two-phase installation**: Tools first, then identity setup

### 🔧 **Developer-Friendly**

- **Comprehensive logging**: All operations logged to files
- **Colorized output**: Clear visual feedback
- **Error handling**: Graceful failures with helpful messages
- **WSL integration**: Seamless Windows/Linux key sharing
- **Extensible**: Easy to add new modules

---

## 🚀 Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/jwogrady/wiz/main/bin/bootstrap | bash
```

This will:
1. Clone the repository to `~/wiz`
2. Run Phase 1: Development Tools Installation
3. Run Phase 2: Identity & SSH Setup

### Manual Installation

```bash
# Clone repository
git clone https://github.com/jwogrady/wiz.git ~/wiz
cd ~/wiz

# Run installer
./bin/install
```

---

## 📖 Usage

### Basic Usage

```bash
# Full installation (interactive)
./bin/install

# Non-interactive with all options
./bin/install \
  --name="John Doe" \
  --email="john@example.com" \
  --github="johndoe"

# Dry-run (preview changes)
./bin/install --dry-run

# Skip identity setup, only install development tools
./bin/install --skip-identity

# Skip development tools, only setup identity
./bin/install --skip-modules
```

### Module Selection

```bash
# Install specific modules only
./bin/install --skip-identity --module=node,neovim

# Skip specific modules
./bin/install --skip=starship,bun

# List all available modules
./bin/install --list

# Show dependency graph
./bin/install --graph
```

### SSH Key Management

```bash
# Import keys from archive
./bin/install --keys-path=/mnt/c/Users/john/keys.tar.gz

# Force re-import (overwrite existing)
./bin/install --force --keys-path=/mnt/c/Users/john/keys.tar.gz

# Test SSH setup
./scripts/test_github.sh
```

### Advanced Options

```bash
# Enable verbose output
./bin/install --verbose

# Enable debug mode (shell tracing)
./bin/install --debug

# Force reinstall all modules
./bin/install --force
```

---

## 📦 Available Modules

| Module | Description | Dependencies |
|--------|-------------|--------------|
| `essentials` | Core system packages and build tools | None |
| `zsh` | Zsh shell with Oh My Zsh framework | essentials |
| `starship` | Cross-shell prompt with custom theme | zsh |
| `node` | Node.js LTS via NVM | essentials |
| `bun` | Bun JavaScript runtime | essentials |
| `neovim` | Neovim editor with Lua config | essentials |
| `summary` | Installation summary and next steps | ALL |

### Module Details

#### Essentials
Installs ~50+ essential packages including:
- Build tools: `gcc`, `make`, `cmake`, `build-essential`
- Development: `git`, `curl`, `wget`, `jq`, `tree`
- Network utilities: `nmap`, `netcat`, `mtr`, `traceroute`
- Monitoring: `htop`, `btop`, `neofetch`, `glances`
- Docker: `docker.io`, `docker-compose`
- And more...

#### Zsh
- Installs Zsh shell
- Configures Oh My Zsh framework
- Sets up common plugins (git, colored-man-pages, extract)
- Sets default shell to Zsh

#### Starship
- Installs Starship prompt
- Applies custom "Cosmic Oasis" theme
- Configures shell integration for Zsh and Bash

#### Node.js
- Installs NVM (Node Version Manager)
- Installs Node.js LTS version
- Configures npm and Corepack
- Sets up shell integration

#### Bun
- Installs Bun runtime
- Provides package manager, test runner, and bundler
- Configures shell integration

#### Neovim
- Installs Neovim editor
- Creates basic Lua configuration structure
- Sets up default configuration directory

---

## 🏗️ Architecture

### Directory Structure

```
wiz/
├── bin/
│   ├── bootstrap          # One-line installer script
│   └── install            # Main installer script
├── lib/
│   ├── common.sh          # Common utilities and helpers
│   ├── module-base.sh     # Module framework and dependency management
│   └── modules/
│       ├── install_essentials.sh
│       ├── install_zsh.sh
│       ├── install_starship.sh
│       ├── install_node.sh
│       ├── install_bun.sh
│       ├── install_neovim.sh
│       └── install_summary.sh
├── config/
│   └── starship_linux.toml  # Starship configuration
├── scripts/
│   ├── test_dry_run.sh      # Dry-run smoke test
│   └── test_github.sh       # GitHub connectivity test
├── docs/
│   ├── CODE_REVIEW.md       # Code review documentation
│   ├── RELEASE.md           # Release process guide
│   └── SSH_KEYS.md          # SSH key management guide
├── logs/                    # Installation logs
└── .wiz/                    # State and cache directory
    ├── state/               # Module completion state
    ├── cache/               # Cache files
    └── backups/             # Backup files
```

### Module System

Each module follows a standard interface:

```bash
# Module metadata
MODULE_NAME="example"
MODULE_VERSION="0.2.0"
MODULE_DESCRIPTION="Description of module"
MODULE_DEPS="dependency1 dependency2"

# Required functions
describe_example() {
    # Show what will be installed
}

install_example() {
    # Installation logic
}

verify_example() {
    # Verification that installation succeeded
}
```

### Dependency Management

Modules declare dependencies, and Wiz automatically:
- Resolves dependency order using topological sorting
- Detects circular dependencies
- Installs dependencies before dependents
- Shows dependency graph with `--graph`

---

## 🔐 SSH Key Management

Wiz automatically manages SSH keys with the following priority:

1. **Explicit `--keys-path`** argument (highest priority)
2. **Windows archive**: `C:\Users\{USER}\keys.tar.gz`
3. **Windows `.ssh` directory**: `/mnt/c/Users/{USER}/.ssh`
4. **Generate new key** if none found

### Archive Format

The `keys.tar.gz` archive should contain a `.ssh` directory:

```
keys.tar.gz
└── .ssh/
    ├── id_ed25519
    ├── id_ed25519.pub
    ├── id_vultr
    ├── id_vultr.pub
    └── ... (other keys)
```

### SSH Agent Configuration

SSH keys are automatically loaded into `ssh-agent`:
- On shell startup (via `.zshrc` or `.bashrc`)
- During installation
- All private keys in `~/.ssh/` are loaded

For more details, see [SSH Keys Documentation](docs/SSH_KEYS.md).

---

## 🧪 Testing

### Dry-Run Test

```bash
# Test installer in dry-run mode
./scripts/test_dry_run.sh
```

This verifies:
- Installer executes without errors
- No system changes are made
- Output contains expected indicators

### GitHub Connectivity Test

```bash
# Test SSH key setup and GitHub connectivity
./scripts/test_github.sh
```

This checks:
- SSH keys are present
- SSH agent is running
- GitHub authentication works
- Repository access is configured

---

## 📝 Configuration

### Environment File

After Phase 2, configuration is saved to `.env`:

```bash
# Wiz Configuration
GIT_NAME="John Doe"
GIT_EMAIL="john@example.com"
GITHUB_USERNAME="johndoe"
WIN_USER="john"
```

### State Management

Module completion state is stored in `~/.wiz/state/`:

```bash
# Check if a module is complete
cat ~/.wiz/state/essentials

# Status: complete | failed | not-started
```

### Logging

All operations are logged to `logs/install_YYYY-MM-DD.log`:

```bash
# View today's log
tail -f logs/install_$(date +%F).log

# Search logs
grep ERROR logs/*.log
```

---

## 🔧 Development

### Adding a New Module

1. Create module file: `lib/modules/install_<name>.sh`

2. Implement required functions:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../module-base.sh"

MODULE_NAME="mymodule"
MODULE_VERSION="0.2.0"
MODULE_DESCRIPTION="My custom module"
MODULE_DEPS="essentials"  # Optional dependencies

describe_mymodule() {
    echo "This module installs..."
}

install_mymodule() {
    log "Installing mymodule..."
    # Installation logic here
}

verify_mymodule() {
    command_exists mymodule || return 1
    return 0
}
```

3. Register in `bin/install`:

```bash
DEFAULT_MODULES=(
    essentials
    # ... other modules
    mymodule  # Add here
)
```

4. Update dependency map in `lib/module-base.sh`:

```bash
declare -gA MODULE_DEPS=(
    # ... existing deps
    [mymodule]="essentials"
)
```

### Common Utilities

Wiz provides many utility functions in `lib/common.sh`:

```bash
# Logging
log "Info message"
warn "Warning message"
error "Error message"
success "Success message"
debug "Debug message"

# Command execution (dry-run aware)
run "command to execute"

# Package management
install_package "package-name"
install_packages "pkg1" "pkg2" "pkg3"

# File operations
atomic_write "$file" "$content"
backup_file "$file"
append_to_file_once "$file" "marker" "$content"

# Environment detection
detect_os           # Returns: ubuntu, debian, etc.
is_wsl              # Returns: 0 if WSL, 1 otherwise
detect_windows_user # Returns: Windows username

# Command utilities
command_exists "cmd"  # Returns: 0 if exists, 1 otherwise
get_command_version "cmd"  # Returns: version string
```

---

## 📚 Documentation

- **[SSH Keys Guide](docs/SSH_KEYS.md)** - SSH key management details
- **[Release Process](docs/RELEASE.md)** - How releases work
- **[Code Review](docs/CODE_REVIEW.md)** - Code quality guidelines
- **[Bash Style Guide](docs/STATUS26_BASH_STYLE_GUIDE_v1.md)** - Status26 Bash coding standards
- **[Conventional Commits Setup](docs/CONVENTIONAL_COMMITS_SETUP.md)** - Git hooks and commit message validation

---

## 🐛 Troubleshooting

### Installation Fails

1. **Check logs**: `tail -f logs/install_$(date +%F).log`
2. **Enable debug mode**: `./bin/install --debug`
3. **Dry-run first**: `./bin/install --dry-run`

### SSH Keys Not Importing

1. **Check Windows path**: Ensure `C:\Users\{USER}\keys.tar.gz` exists
2. **Verify archive format**: Should contain `.ssh` directory
3. **Manual import**: `./bin/install --keys-path=/path/to/archive.tar.gz`

### Module Installation Fails

1. **Check dependencies**: `./bin/install --graph`
2. **Force reinstall**: `./bin/install --force`
3. **Install specific module**: `./bin/install --module=module_name`

### Permission Errors

- Ensure you have `sudo` access
- Check file permissions: `ls -la ~/.ssh`
- Verify SSH agent: `ssh-add -l`

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Follow the [Bash Style Guide](docs/STATUS26_BASH_STYLE_GUIDE_v1.md)
2. Run `./scripts/check_bash_style.sh` before submitting PRs
3. Ensure all scripts pass ShellCheck (see `.shellcheckrc`)
4. Use [Conventional Commits](https://www.conventionalcommits.org/) format (validated by commitlint)
5. Add tests for new features
6. Update documentation
7. See [RELEASE.md](docs/RELEASE.md) for versioning and release process

### Commit Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`

---

## 📄 License

This project is open source. See repository for license details.

---

## 🙏 Acknowledgments

- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework
- [Starship](https://starship.rs/) - Cross-shell prompt
- [NVM](https://github.com/nvm-sh/nvm) - Node Version Manager
- [Bun](https://bun.sh/) - JavaScript runtime
- [Neovim](https://neovim.io/) - Modern Vim fork

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/jwogrady/wiz/issues)
- **Repository**: [jwogrady/wiz](https://github.com/jwogrady/wiz)

---

**Made with ✨ by the Wiz community**

