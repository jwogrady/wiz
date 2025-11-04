# 🌌 Wiz - Terminal Magic ✨

![Version](https://img.shields.io/badge/version-0.3.1-blueviolet)
![License](https://img.shields.io/badge/license-MIT-blue)
![Shell](https://img.shields.io/badge/shell-bash%205.0%2B-green)
![Platform](https://img.shields.io/badge/platform-WSL%20%7C%20Linux-orange)

**Wiz** is a modular, idempotent developer environment bootstrapper for WSL and Linux systems. It automates the complete setup of your terminal environment, from Git identity and SSH keys to development tools and shell enhancements.

## ✨ Features

- 🚀 **One-Command Setup** - Complete environment setup in minutes
- 🔄 **Idempotent** - Safe to run multiple times without breaking your system
- 🧩 **Modular Design** - Install only what you need with dependency resolution
- 🎯 **Smart Dependencies** - Automatic topological sorting of module installation
- 📊 **Progress Tracking** - Clear progress indicators and installation summaries
- 🛡️ **Error Recovery** - Robust error handling with detailed logging
- 🎨 **Beautiful Output** - Color-coded, emoji-enhanced terminal output
- 📝 **Comprehensive Logging** - All operations logged for troubleshooting
- 🔀 **Two-Phase Workflow** - Identity setup first, then tools installation with verification

## 📋 Installation Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  FRESH WSL UBUNTU INSTALLATION                              │
│  $ cd ~                                                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  PHASE 1: Identity & SSH Setup (Automated)                  │
│  $ curl -fsSL https://...wiz/main/bin/bootstrap | bash      │
│                                                              │
│  Bootstrap (automatic):                                      │
│  ✓ Auto-detect Windows username                              │
│  ✓ Import SSH keys from C:\Users\{username}\keys.tar.gz     │
│  ✓ Clone wiz repository to ~/wiz (SSH or HTTPS)              │
│                                                              │
│  Identity Setup (interactive):                               │
│  ✓ Configure Git identity (name, email, GitHub)              │
│  ✓ Verify SSH keys (skip if already imported)                │
│  ✓ Configure Git global settings                            │
│  ✓ Set up SSH agent for persistence                          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  VERIFICATION PROMPT                                         │
│  "Continue with Phase 2 installation? [Y/n]:"               │
│                                                              │
│  → Press Y: Continue to Phase 2                             │
│  → Press N: Exit (run Phase 2 later manually)               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼ (if Y)
┌─────────────────────────────────────────────────────────────┐
│  PHASE 2: Development Tools Installation                    │
│  Runs automatically or: ./bin/install --skip-identity       │
│                                                              │
│  ✓ Essential packages (~50+ tools)                          │
│  ✓ Zsh + Oh My Zsh                                          │
│  ✓ Starship prompt                                          │
│  ✓ Node.js LTS via NVM                                      │
│  ✓ Bun runtime                                              │
│  ✓ Neovim editor                                            │
│  ✓ Installation summary                                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  COMPLETE! ✨                                               │
│  Restart terminal or: source ~/.zshrc                       │
└─────────────────────────────────────────────────────────────┘
```

### Why Two Phases?

**Phase 1 (Identity)** sets up your development identity and authentication:
- Quick to complete (1-2 minutes)
- Requires user input for personal information
- Essential for Git and SSH operations
- Can be verified before proceeding

**Phase 2 (Tools)** installs development environment:
- Takes longer (5-10 minutes)
- Fully automated, no user input needed
- Can be run later if you need to verify Phase 1 first
- Can be customized with module selection

## 🚀 Quick Start

### Two-Phase Installation

Wiz uses a two-phase installation process for better control and verification:

#### Phase 1: Identity & SSH Setup

After installing WSL and dropping into Ubuntu shell:

```bash
curl -fsSL https://raw.githubusercontent.com/jwogrady/wiz/main/bin/bootstrap | bash
```

**What Phase 1 does:**
1. ✅ Auto-detects Windows username and imports SSH keys from `C:\Users\{username}\keys.tar.gz` (if available) for repository access
2. ✅ Clones the Wiz repository to `~/wiz` (via SSH if keys available, otherwise HTTPS)
3. ✅ Configures Git identity (name, email, GitHub username)
4. ✅ Sets up SSH keys (auto-import from `C:\Users\{username}\keys.tar.gz`, Windows `.ssh`, or generate new)
5. ✅ Configures global Git settings and `.gitignore`
6. ✅ Sets up SSH agent for persistent authentication

**After Phase 1 completes**, you'll see a summary and verification prompt.

#### Phase 2: Development Tools Installation

When you're ready to install development tools:

```bash
cd ~/wiz
./bin/install --skip-identity
```

Or the installer will prompt you to continue automatically after Phase 1.

**What Phase 2 installs:**
1. ✅ Essential system packages (~50+ tools)
2. ✅ Zsh with Oh My Zsh framework
3. ✅ Starship cross-shell prompt
4. ✅ Node.js LTS via NVM
5. ✅ Bun JavaScript runtime
6. ✅ Neovim editor
7. ✅ Installation summary with next steps

### Run Phase 2 Later

If you chose to skip Phase 2 during the initial setup, you can run it anytime:

```bash
cd ~/wiz
./bin/install --skip-identity
```

### Non-Interactive Phase 1

Pass all parameters via command line to skip prompts:

```bash
curl -fsSL https://raw.githubusercontent.com/jwogrady/wiz/main/bin/bootstrap | bash -s -- \
  --name="John Doe" \
  --email="john@example.com" \
  --github="johndoe"
```

### Alternative: Manual Clone & Install

```bash
git clone https://github.com/jwogrady/wiz.git ~/wiz
cd ~/wiz
./bin/install
```

### Skip Identity Setup (Modules Only)

```bash
./bin/install --skip-identity
```

### Install Specific Modules

```bash
./bin/install --skip-identity --module=node,neovim
```

### Dry Run (See What Would Happen)

```bash
./bin/install --dry-run
```

## 📦 Available Modules

| Module | Version | Description |
|--------|---------|-------------|
| **essentials** | 0.2.0 | Core system packages and build tools (gcc, make, git, curl, docker, etc.) |
| **zsh** | 0.2.0 | Zsh shell with Oh My Zsh framework and plugins |
| **starship** | 0.2.0 | Cross-shell prompt with No Nerd Font preset (WSL-friendly) |
| **node** | 0.2.0 | Node.js LTS via NVM with shell integration |
| **bun** | 0.2.0 | Bun JavaScript runtime and package manager |
| **neovim** | 0.2.0 | Neovim editor with basic Lua configuration |
| **summary** | 0.2.0 | Installation summary and next steps |

### List All Modules

```bash
./bin/install --list
```

### View Dependency Graph

```bash
./bin/install --graph
```

## 🎯 Usage Examples

### Recommended: Two-Phase Installation

**Step 1: Fresh WSL Installation**
```bash
# In fresh Ubuntu WSL shell
cd ~
curl -fsSL https://raw.githubusercontent.com/jwogrady/wiz/main/bin/bootstrap | bash
```

**Step 2: Review and Continue**
The installer will prompt you after Phase 1:
```
Continue with Phase 2 installation? [Y/n]:
```
- Press `Y` or `Enter` to continue with tool installation
- Press `N` to exit and run Phase 2 later

### Interactive Setup (Default)

```bash
./bin/install
```

Prompts for:
- Git user name
- Git email
- GitHub username
- Windows username (for SSH key import fallback in WSL)

### Non-Interactive Setup

```bash
./bin/install \
  --name="John Doe" \
  --email="john@example.com" \
  --github="johndoe"
```

### Install Only Specific Tools

```bash
# Only Node.js and Neovim
./bin/install --skip-identity --module=node,neovim

# Everything except Bun
./bin/install --skip-identity --skip=bun

# Force reinstall everything
./bin/install --force
```

### Developer Mode

```bash
# Enable debug output
./bin/install --debug

# Enable verbose logging
./bin/install --verbose

# Dry-run with debug
./bin/install --dry-run --debug
```

## 🏗️ Architecture

### Project Structure

```
wiz/
├── bin/
│   └── install              # Main installer orchestrator
├── lib/
│   ├── common.sh            # Shared utilities (logging, file ops, etc.)
│   ├── module-base.sh       # Module framework and dependency resolution
│   └── modules/
│       ├── install_essentials.sh
│       ├── install_zsh.sh
│       ├── install_starship.sh
│       ├── install_node.sh
│       ├── install_bun.sh
│       ├── install_neovim.sh
│       └── install_summary.sh
└── logs/                    # Installation logs (auto-generated)
```

### Module System

Each module implements three functions:

- `describe_<module>()` - What will be installed
- `install_<module>()` - Installation logic
- `verify_<module>()` - Verification that installation succeeded

Modules declare dependencies, and Wiz automatically determines the correct installation order using topological sorting.

### State Management

Installation state is tracked in `~/.wiz/state/` with per-module status files. This enables:
- Skipping already-completed modules
- Resuming failed installations
- Force reinstallation when needed

## ⚙️ Configuration

### Environment Variables

```bash
# Dry-run mode (show commands without executing)
export WIZ_DRY_RUN=1

# Force reinstall all modules
export WIZ_FORCE_REINSTALL=1

# Log level (0=DEBUG, 1=INFO, 2=WARN, 3=ERROR)
export WIZ_LOG_LEVEL=0

# Verbose output
export WIZ_VERBOSE=1

# Stop on first error (default: 1)
export WIZ_STOP_ON_ERROR=0
```

### Configuration Files

After installation, configuration files are created:

- `~/.zshrc` - Zsh configuration
- `~/.bashrc` - Bash configuration (with auto-switch to Zsh)
- `~/.config/starship.toml` - Starship prompt configuration
- `~/.config/nvim/init.lua` - Neovim configuration
- `~/.gitconfig` - Global Git configuration
- `~/.gitignore_global` - Global Git ignore patterns

## 🛠️ Command-Line Options

```
Options:
  --help              Show help message
  --dry-run           Show commands without executing
  --force             Force reinstall of all modules
  --debug             Enable shell execution tracing
  --verbose           Enable verbose output
  
Identity Setup:
  --name=NAME         Set Git user.name (skips prompt)
  --email=EMAIL       Set Git user.email (skips prompt)
  --github=USER       Set GitHub username (skips prompt)
  --win-user=USER     Set Windows username for SSH key import (fallback)
  --keys-path=PATH    Provide SSH key archive manually (overrides auto-detection)
  
Module Control:
  --skip-identity     Skip identity setup, only install modules
  --skip-modules      Skip module installation, only setup identity
  --module=NAME       Install only specific module(s) (comma-separated)
  --skip=NAME         Skip specific module(s) (comma-separated)
  --list              List all available modules
  --graph             Show dependency graph
```

## 📋 What Gets Installed

### Essential Packages (~50+)

**Build Tools**: gcc, make, cmake, build-essential, cabal

**Development**: git, curl, wget, jq, tree, unzip, zip

**Network Utilities**: nmap, mtr, netcat, dnsutils, traceroute, whois

**Monitoring**: htop, btop, glances, neofetch, lsof, strace

**Docker**: docker.io, docker-compose

**Editors**: nano, vim, neovim

**GitHub CLI**: gh

### Shell Environment

- **Zsh** with Oh My Zsh framework
- **Starship** prompt (No Nerd Font preset for WSL compatibility)
- **Node.js LTS** via NVM with npm configuration
- **Bun** JavaScript runtime
- **Neovim** with basic Lua configuration

### Git Configuration

- User identity (name, email)
- Default branch: `main`
- Global `.gitignore`
- Useful aliases (st, co, br, cm, lg, etc.)

### SSH Setup

SSH keys are automatically imported in the following priority order:

1. **Explicit `--keys-path` argument** - Manual archive path (overrides all auto-detection)
2. **`C:\Users\{WIN_USER}\keys.tar.gz/.ssh`** - Directory path (if archive exists as directory)
3. **`C:\Users\{WIN_USER}\keys.tar.gz`** - Archive file (automatically detected based on Windows username, extracts `.ssh` directory)
4. **Windows user `.ssh` directory** - `/mnt/c/Users/{WIN_USER}/.ssh` (fallback)
5. **Generate new ED25519 key** - If no keys found

**Note**: Windows username is automatically detected (via `whoami.exe`, `USERNAME` env var, or scanning `/mnt/c/Users/`). Keys will be imported from `C:\Users\{detected-username}\keys.tar.gz` if available.

**SSH Agent Configuration:**
- Automatically starts `ssh-agent` when entering WSL
- Loads **all** private keys from `~/.ssh/` (including named keys like `id_vultr`, `id_jwogrady`, etc.)
- Keys are loaded immediately during installation and on every shell start

## 🔍 Troubleshooting

### Enable Debug Mode

```bash
./bin/install --debug --verbose
```

### Check Logs

```bash
# View today's log
cat ~/wiz/logs/install_$(date +%F).log

# Watch log in real-time
tail -f ~/wiz/logs/install_$(date +%F).log
```

### Common Issues

**Module fails to install**
- Check the log file for detailed error messages
- Try running with `--force` to reinstall
- Ensure you have sudo privileges

**Command not found after installation**
- Restart your terminal or run: `source ~/.zshrc`
- Check if the command's directory is in your PATH

**SSH keys not working**
- Verify keys exist: `ls -la ~/.ssh/`
- Check permissions: `chmod 600 ~/.ssh/id_*` (or for named keys: `chmod 600 ~/.ssh/id_vultr ~/.ssh/id_jwogrady`)
- Test SSH agent: `ssh-add -l` (should show all loaded keys)
- Verify archive exists: `ls -la /mnt/c/Users/john/keys.tar.gz`
- Force re-import: `./bin/install --force --skip-modules`

**Oh My Zsh installation hangs**
- Kill the process and run with `--force`
- Manually remove `~/.oh-my-zsh` and retry

### Reset Installation

```bash
# Remove state files
rm -rf ~/.wiz/state/

# Remove installed configurations (BE CAREFUL!)
rm -rf ~/.oh-my-zsh ~/.nvm ~/.config/nvim ~/.config/starship.toml

# Run fresh installation
./bin/install --force
```

## 🧪 Testing

### Test Installation (Dry-Run)

```bash
./bin/install --dry-run --verbose
```

### Verify Installation

```bash
# Check module status
ls -la ~/.wiz/state/

# Verify tools are installed
command -v git node npm nvim zsh starship bun docker

# Check versions
git --version
node --version
nvim --version
starship --version
```

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Follow conventions**:
   - Use conventional commits: `feat:`, `fix:`, `docs:`, etc.
   - Follow existing code style
   - Add error handling
   - Make modules idempotent
4. **Test thoroughly**: Run with `--dry-run` and test on fresh system
5. **Submit a pull request**

### Working with Issues

When fixing bugs or adding features related to GitHub issues:

1. **Reference the issue** in your commit message:
   ```bash
   # Auto-closes issue when merged
   git commit -m "fix(module): description of fix
   
   Fixes #123"
   
   # Just references without closing
   git commit -m "feat(module): partial work on feature
   
   Related to #123"
   ```

2. **Document the fix** by commenting on the issue:
   ```bash
   # Using GitHub CLI
   gh issue comment 123 --body "Fixed in commit abc1234
   
   ### Root Cause
   Explanation of what was wrong
   
   ### Solution  
   What you changed and why
   
   ### Testing
   How to verify the fix works"
   
   # Or use the web interface at:
   # https://github.com/jwogrady/wiz/issues/123
   ```

3. **Issue will auto-close** when commit with `Fixes #123` reaches master branch

4. **Keywords that auto-close issues**:
   - `Fixes #123`, `Closes #123`, `Resolves #123`
   - `Fix #123`, `Close #123`, `Resolve #123`

For more details, see [Linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue).

### Adding a New Module

1. Create `lib/modules/install_yourmodule.sh`
2. Implement the three required functions:
   - `describe_yourmodule()`
   - `install_yourmodule()`
   - `verify_yourmodule()`
3. Set module metadata:
   - `MODULE_NAME="yourmodule"`
   - `MODULE_VERSION="0.2.0"`
   - `MODULE_DESCRIPTION="What it does"`
   - `MODULE_DEPS="space separated dependencies"`
4. Add to `DEFAULT_MODULES` in `bin/install`
5. Add to dependency map in `lib/module-base.sh`
6. Test thoroughly!

## 📚 Documentation

- **README.md** (this file) - Project overview and usage
- **CHANGELOG.md** - Auto-generated release notes and version history
- **docs/RELEASE.md** - Release process and conventional commit guide
- **lib/common.sh** - Inline documentation for utility functions
- **lib/module-base.sh** - Module interface documentation
- **logs/** - Detailed installation logs

## 🏷️ Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/) and uses automated releases via [Release Please](https://github.com/googleapis/release-please).

- **MAJOR** version: Incompatible API changes (BREAKING CHANGE in commit)
- **MINOR** version: New functionality (backward-compatible) (feat: commits)
- **PATCH** version: Bug fixes (backward-compatible) (fix: commits)

Releases are automatically created when commits are merged to master using [conventional commit messages](https://www.conventionalcommits.org/).

**Current Version**: `0.3.1`

For details on the release process, see [docs/RELEASE.md](docs/RELEASE.md).

### Version History

- **v0.3.1** (2025-11-04) - Patch Release: Cleanup, Stability, and Best Practices
  - Removed committed install logs and enhanced .gitignore
  - Improved logging policy (local-only logs, never committed)
  - Minor performance optimizations (reduced redundant checks)
  - Enhanced log truncation for dry-run and debug modes
  - Improved idempotency and error handling

- **v0.2.0** (2025-11-03) - Major Refactor and Stability Release
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
  
  - **Critical Bug Fixes**:
    - Fixed installer argument passing for starship and bun (bash pipe issues)
    - Corrected README installation workflow (bootstrap vs install)
    - Fixed starship verification hanging
    - Removed interactive prompts from curl-piped bootstrap
    - Improved phase completion messaging
    - Enhanced error handling and recovery
  
  - **Code Quality**:
    - Applied easybash coding style guide standards
    - Consistent color variable naming (COLOR_ prefix)
    - Proper array and heredoc formatting
    - Readonly constants for configuration
    - Comprehensive inline documentation
    - Idempotent design - safe to run multiple times
  
  - **Breaking Changes from v0.1.0**:
    - Removed old `install.sh` and `init/bootstrap.sh` structure
    - Removed individual module scripts in `init/modules/`
    - Removed deprecated tools (hostmaster-tools, openai-cli, shellcheck standalone)
    - New directory structure: `bin/` and `lib/` instead of `init/`
    - Different command-line interface (see `--help`)
  
  - **Migration from v0.1.0**:
    - v0.2.0 is a fresh install - not an in-place upgrade
    - Backup your existing `~/.wiz/` directory if upgrading
    - New modules will respect existing configurations
    - State management allows resuming failed installations

- **v0.1.0** (2025-10-XX) - Initial release
  - Basic modular installer with `install.sh` entry point
  - Individual module scripts in `init/modules/`
  - Simple sequential installation
  - Git identity and SSH key setup
  - Docker, Node.js, Neovim, GitHub CLI installation

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

Copyright (c) 2025 John W. O'Grady

## 🙏 Acknowledgments

- [Oh My Zsh](https://ohmyz.sh/) - Community-driven Zsh framework
- [Starship](https://starship.rs/) - Cross-shell prompt
- [NVM](https://github.com/nvm-sh/nvm) - Node Version Manager
- [Neovim](https://neovim.io/) - Modern Vim fork

---

<div align="center">

**🌌 Wiz - Terminal Magic ✨**

*Making terminal setup magical since 2025*

[Report Bug](https://github.com/jwogrady/wiz/issues) · [Request Feature](https://github.com/jwogrady/wiz/issues)

</div>
