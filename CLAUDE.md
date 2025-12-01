# CLAUDE.md - AI Assistant Guide for Wiz

This document provides comprehensive guidance for AI assistants working with the Wiz codebase.

## Project Overview

**Wiz** is a modular developer environment bootstrapper for Linux and WSL. It provides a two-phase installation system:

1. **Phase 1 (Development Tools)**: Installs essentials, zsh, starship, node, bun, neovim
2. **Phase 2 (Identity Setup)**: Configures Git identity and SSH key management

**Current Version**: 0.4.0

## Repository Structure

```
wiz/
├── bin/
│   ├── bootstrap          # One-line installer (curl | bash)
│   └── install            # Main installer script (1195 lines)
├── lib/
│   ├── common.sh          # Shared utilities (logging, file ops, env detection)
│   ├── module-base.sh     # Module framework with dependency management
│   └── modules/
│       ├── install_essentials.sh   # Core system packages (~50+)
│       ├── install_zsh.sh          # Zsh + Oh My Zsh
│       ├── install_starship.sh     # Starship prompt
│       ├── install_node.sh         # Node.js via NVM
│       ├── install_bun.sh          # Bun runtime
│       ├── install_neovim.sh       # Neovim editor
│       └── install_summary.sh      # Installation summary
├── config/
│   └── starship_linux.toml         # Starship theme config
├── scripts/
│   ├── test_dry_run.sh             # Dry-run smoke test
│   ├── test_github.sh              # GitHub connectivity test
│   ├── check_bash_style.sh         # Style checker
│   ├── validate_commit_msg.sh      # Commit message validator
│   └── setup_git_hooks.sh          # Git hooks installer
├── docs/
│   ├── STATUS26_BASH_STYLE_GUIDE_v1.md  # Bash coding standards
│   ├── CONVENTIONAL_COMMITS_SETUP.md    # Commit conventions
│   ├── RELEASE.md                       # Release process
│   ├── SSH_KEYS.md                      # SSH management guide
│   └── CODE_REVIEW.md                   # Code review guidelines
├── .github/workflows/
│   ├── shellcheck.yml              # ShellCheck CI
│   ├── commitlint.yml              # Commit lint CI
│   └── release-please.yml          # Automated releases
├── commitlint.config.js            # Commit message rules
├── .shellcheckrc                   # ShellCheck configuration
├── .gitmessage                     # Commit template
└── CHANGELOG.md                    # Auto-generated changelog
```

## Key Technical Decisions

### Bash Standards

All scripts MUST:
- Start with `#!/usr/bin/env bash`
- Use strict mode: `set -euo pipefail` and `IFS=$'\n\t'`
- Pass ShellCheck with zero errors
- Use 2-space indentation (no tabs)
- Max line length: 80 characters
- Use `[[ ]]` for tests (not `[ ]`)
- Use `(( ))` for arithmetic
- Always quote variables: `"${var}"`, `"$(cmd)"`
- Declare constants as `readonly ALL_CAPS`
- Use `local` in functions with `snake_case` names

### Module Interface

Every module in `lib/modules/` MUST implement:

```bash
# Module metadata (required)
MODULE_NAME="mymodule"
MODULE_VERSION="0.2.0"
MODULE_DESCRIPTION="Human-readable description"
MODULE_DEPS="dependency1 dependency2"  # Space-separated, or empty

# Required functions
describe_mymodule() {
    # Show what will be installed (displayed before installation)
}

install_mymodule() {
    # Main installation logic
    # Use: log, warn, error, success, run functions
    # Return 0 on success, non-zero on failure
}

verify_mymodule() {
    # Verification that installation succeeded
    # Return 0 if verified, 1 if failed
}
```

### Dependency Graph

```
essentials (no deps) ─┬─► node
                      ├─► bun
                      └─► neovim

zsh (no deps) ─────────► starship

summary (ALL) ─────────► runs last
```

## Common Utility Functions

From `lib/common.sh`:

```bash
# Logging (all output colorized)
log "Info message"           # Green arrow
warn "Warning"               # Yellow warning
error "Error" "hint"         # Red X with optional troubleshooting hint
success "Done"               # Green checkmark
debug "Verbose info"         # Cyan (only if LOG_LEVEL=0)

# Dry-run aware execution
run "command to execute"     # Logs and executes, shows [DRY-RUN] if enabled

# File operations
atomic_write "$file" "$content"           # Write only if different
backup_file "$file"                       # Create timestamped backup
append_to_file_once "$file" "marker" "$content"  # Idempotent append

# Package management
install_package "pkg"                     # Install single package
install_packages "pkg1" "pkg2" "pkg3"     # Batch install

# Environment detection
detect_os                    # Returns: ubuntu, debian, etc.
is_wsl                       # Returns: 0 if WSL, 1 otherwise
detect_windows_user          # Returns: Windows username
command_exists "cmd"         # Returns: 0 if exists
package_installed "pkg"      # Returns: 0 if installed

# Version utilities
get_command_version "cmd"    # Extract version string
check_command_installed "cmd" "name"  # Check + log if installed
```

## Commit Message Convention

All commits MUST follow Conventional Commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Valid Types**:
- `feat`: New feature (MINOR bump)
- `fix`: Bug fix (PATCH bump)
- `docs`: Documentation only
- `style`: Code formatting
- `refactor`: Code restructuring
- `perf`: Performance improvement
- `test`: Adding/updating tests
- `build`: Build system changes
- `ci`: CI configuration
- `chore`: Maintenance tasks
- `revert`: Reverting commits

**Breaking Changes**: Use `!` or `BREAKING CHANGE:` footer (MAJOR bump)

**Examples**:
```bash
feat(modules): add redis installation module
fix(install): correct SSH key import path validation
docs(readme): update installation instructions
chore(deps): update commitlint configuration
```

## Testing

### Run Tests Before Committing

```bash
# Dry-run smoke test
./scripts/test_dry_run.sh

# ShellCheck all scripts
shellcheck bin/* lib/*.sh lib/modules/*.sh scripts/*.sh

# Test installer in dry-run mode
./bin/install --dry-run --skip-identity
```

### Key Test Flags

```bash
./bin/install --dry-run         # Preview without changes
./bin/install --verbose         # Detailed output
./bin/install --debug           # Shell tracing (set -x)
./bin/install --list            # List available modules
./bin/install --graph           # Show dependency graph
```

## CI/CD Workflows

1. **ShellCheck** (`shellcheck.yml`): Validates all `.sh` files
2. **Commitlint** (`commitlint.yml`): Validates commit messages
3. **Release Please** (`release-please.yml`): Automated versioning/releases

## State Management

Module state stored in `~/.wiz/state/`:
- `complete`: Module finished successfully
- `failed`: Module encountered error
- Check with: `is_module_complete "module_name"`
- Force reinstall with: `--force` flag or `WIZ_FORCE_REINSTALL=1`

## Adding a New Module

1. Create `lib/modules/install_<name>.sh` following the module interface
2. Add to `DEFAULT_MODULES` array in `bin/install` (line ~82)
3. Add dependency mapping in `lib/module-base.sh` `MODULE_DEPS` array (line ~51)
4. Test with: `./bin/install --module=<name> --dry-run`

## Important Environment Variables

```bash
WIZ_DRY_RUN=1          # Enable dry-run mode
WIZ_VERBOSE=1          # Enable verbose output
WIZ_LOG_LEVEL=0        # 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR
WIZ_FORCE_REINSTALL=1  # Force reinstall completed modules
WIZ_STOP_ON_ERROR=0    # Continue on module failures
WIZ_AUTO_RELOAD_SHELL=1 # Auto-reload shell after install
```

## Code Review Checklist

When modifying scripts, ensure:

- [ ] Passes `shellcheck -x`
- [ ] Uses strict mode (`set -euo pipefail`)
- [ ] Quotes all variable expansions
- [ ] Uses `run` function for commands (dry-run aware)
- [ ] Logs appropriately (log/warn/error/success)
- [ ] Handles errors gracefully
- [ ] No `eval` usage
- [ ] HTTPS for all network operations
- [ ] SHA256 verification for external downloads
- [ ] Clean up temp files via trap

## Common Tasks for AI Assistants

### Adding Package to Essentials

Edit `lib/modules/install_essentials.sh`, add to appropriate array:
- `NETWORK_UTILS` for network tools
- `MONITORING_TOOLS` for system monitoring
- `BUILD_TOOLS` for compilers/build systems
- `DEV_ESSENTIALS` for development tools

### Modifying Shell Configuration

Shell configs are added via `append_to_file_once` to be idempotent. Look for patterns like:
```bash
append_to_file_once "$zshrc" "# Wiz marker" "config content"
```

### Debugging Installation Issues

1. Run with `--debug` for shell tracing
2. Check logs: `tail -f logs/install_$(date +%F).log`
3. Test specific module: `./bin/install --module=<name> --verbose`
4. Check state: `cat ~/.wiz/state/<module>`

### Version Updates

Version is in `README.md` badge and managed by Release Please. Do NOT manually update version - commit messages drive versioning.

## Quick Reference

| Command | Purpose |
|---------|---------|
| `./bin/install` | Full installation |
| `./bin/install --dry-run` | Preview changes |
| `./bin/install --skip-identity` | Only Phase 1 (tools) |
| `./bin/install --skip-modules` | Only Phase 2 (identity) |
| `./bin/install --module=node,bun` | Specific modules |
| `./bin/install --force` | Force reinstall all |
| `./scripts/test_dry_run.sh` | Run smoke tests |
| `shellcheck bin/* lib/*.sh` | Lint scripts |

## References

- [Status26 Bash Style Guide](docs/STATUS26_BASH_STYLE_GUIDE_v1.md)
- [Conventional Commits Setup](docs/CONVENTIONAL_COMMITS_SETUP.md)
- [Release Process](docs/RELEASE.md)
- [SSH Key Management](docs/SSH_KEYS.md)
