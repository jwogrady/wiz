# Wiz — Terminal Magic
<!-- version-0.4.0 -->

Modular developer environment bootstrapper for WSL / Debian-based Linux.
Installs and configures: Zsh + Oh My Zsh, Starship prompt, Node.js (via NVM),
Bun, Neovim, essential system packages, SSH keys, and Git identity.

## Quick Start

```bash
# Curl-pipe bootstrap (clones repo + runs installer)
curl -fsSL https://raw.githubusercontent.com/jwogrady/wiz/master/bin/bootstrap | bash
```

Or, if you already have the repo:

```bash
git clone https://github.com/jwogrady/wiz.git ~/wiz
cd ~/wiz
./bin/install
```

## Usage

```
./bin/install [options]

Options:
  --help, -h          Show help
  --version, -V       Show version
  --dry-run           Print commands without executing
  --force             Force reinstall even if module already completed
  --debug             Enable shell tracing (set -x)
  --verbose           Enable debug-level log output

Module control:
  --module=NAME       Install only specific modules (comma-separated)
  --skip=NAME         Skip specific modules (comma-separated)
  --skip-modules      Skip Phase 1 (tool installation) entirely
  --skip-identity     Skip Phase 2 (Git identity / SSH setup) entirely
  --list              List all available modules
  --graph             Show module dependency graph

Identity setup:
  --name=NAME         Git user.name (skips interactive prompt)
  --email=EMAIL       Git user.email (skips interactive prompt)
  --github=USER       GitHub username (skips interactive prompt)
  --win-user=USER     Windows username for SSH key import
  --keys-path=PATH    Explicit path to keys.tar.gz archive

Version overrides:
  --node-version=VER  Node.js version (default: lts)
  --bun-version=VER   Bun version (default: latest)
  --starship-version=VER  Starship version (default: latest)
```

### Examples

```bash
# Full installation — tools + Git identity
./bin/install

# Tools only, no identity setup
./bin/install --skip-identity

# Identity only, no tool installation
./bin/install --skip-modules

# Install two specific modules
./bin/install --skip-identity --module=node,neovim

# Non-interactive (all values pre-supplied)
./bin/install --name="Jane Doe" --email="jane@example.com" --github="janedoe"

# Preview what would happen, make no changes
./bin/install --dry-run
```

## Modules

| Module | Description | Depends on |
|--------|-------------|------------|
| `essentials` | Core packages: gcc, git, curl, htop, docker, gh, … | — |
| `zsh` | Zsh + Oh My Zsh with git/colored-man-pages plugins | essentials |
| `starship` | Starship prompt (Cosmic Oasis preset) | zsh |
| `node` | NVM + Node.js LTS + npm + Corepack | essentials |
| `bun` | Bun JavaScript runtime + package manager | essentials |
| `neovim` | Neovim editor + basic Lua config | essentials |
| `summary` | Post-install report showing tools, paths, next steps | ALL |

### Module state

Module completion state is persisted in `~/.wiz/state/`.
Re-running `./bin/install` skips already-completed modules unless `--force` is set.

## Repository Layout

```
wiz/
├── bin/
│   ├── bootstrap        # curl-pipe entry point — clones repo, runs install
│   └── install          # main installer (two-phase: tools + identity)
├── lib/
│   ├── common.sh        # core: logging, run/run_stream, OS detection, hooks
│   ├── pkg.sh           # package manager abstraction (apt/dnf/pacman/brew)
│   ├── download.sh      # SHA-256 verification, curl/wget helpers
│   ├── ui.sh            # progress bar, spinner, banner
│   ├── module-base.sh   # module interface, dependency sort, state management
│   ├── ssh.sh           # SSH key import, agent config, fingerprint cache
│   ├── identity.sh      # Git identity validation and .env management
│   └── modules/
│       ├── install_essentials.sh
│       ├── install_zsh.sh
│       ├── install_starship.sh
│       ├── install_node.sh
│       ├── install_bun.sh
│       ├── install_neovim.sh
│       └── install_summary.sh
├── config/
│   └── starship_linux.toml   # Cosmic Oasis Starship preset
├── hooks/
│   ├── pre-install.d/        # hooks run before any module
│   ├── post-install.d/       # hooks run after all modules
│   ├── pre-module.d/         # hooks run before each module (receives $1=name)
│   └── post-module.d/        # hooks run after each module
└── tests/
    ├── run_tests.sh           # BATS test runner
    ├── helpers/
    │   └── common_setup.bash  # shared setup/teardown for all suites
    ├── test_parse_state_value.bats
    ├── test_is_module_complete.bats
    ├── test_get_install_order.bats
    ├── test_has_ssh_keys.bats
    ├── test_wiz_download_verified.bats
    ├── test_wiz_add_shell_block.bats
    └── test_wiz_update_shell_block.bats
```

### Library sourcing chain

```
bin/install
  └── source lib/module-base.sh
        └── source lib/common.sh        (if not already loaded)
              ├── source lib/pkg.sh
              ├── source lib/download.sh
              └── source lib/ui.sh
  └── source lib/identity.sh            (guard-sources common.sh if needed)
  └── source lib/ssh.sh                 (guard-sources common.sh if needed)
```

Modules only need `source "${SCRIPT_DIR}/../module-base.sh"` — all other
functions are available transitively.

## Hooks

Place executable `.sh` files in the appropriate subdirectory of `hooks/`:

```bash
# hooks/pre-install.d/01-custom-setup.sh
#!/usr/bin/env bash
echo "Running before any modules install"
```

Hooks in `pre-module.d/` and `post-module.d/` receive the module name as `$1`.
Non-executable hook files are skipped with a debug message; failures log a
warning but do not stop installation.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WIZ_DRY_RUN` | `0` | `1` = print commands, skip execution |
| `WIZ_LOG_LEVEL` | `1` | `0`=DEBUG `1`=INFO `2`=WARN `3`=ERROR |
| `WIZ_LOG_FILE` | `logs/install_YYYY-MM-DD.log` | Log file path |
| `WIZ_VERBOSE` | `0` | `1` = debug-level log output |
| `WIZ_FORCE_REINSTALL` | `0` | `1` = reinstall even if module is complete |
| `WIZ_STOP_ON_ERROR` | `1` | `0` = continue past module failures |
| `WIZ_NODE_VERSION` | `lts` | Node.js version passed to `nvm install` |
| `WIZ_BUN_VERSION` | `` | Bun version tag (empty = latest) |
| `WIZ_STARSHIP_VERSION` | `` | Starship version tag (empty = latest) |

## Running Tests

Requires [BATS](https://github.com/bats-core/bats-core):

```bash
# Debian/Ubuntu
sudo apt-get install bats

# macOS
brew install bats-core

# npm (anywhere)
npm install -g bats
```

Then:

```bash
./tests/run_tests.sh               # run all suites
./tests/run_tests.sh --tap         # TAP output (for CI)
./tests/run_tests.sh tests/test_has_ssh_keys.bats   # single suite
```

## Requirements

- Bash 4.3+ (required for `local -n` nameref)
- `git`, `ssh-agent`, `tar` (checked at startup by `bin/install`)
- `curl` or `wget` (for downloads; both are optional individually)
- Intended for WSL2 or native Debian/Ubuntu Linux

## License

MIT
