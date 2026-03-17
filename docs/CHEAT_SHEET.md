# Wiz Repo Cheat Sheet

## Running the installer

```bash
./bin/install                                      # interactive, all phases
./bin/install --dry-run                            # preview only, nothing executes
./bin/install --debug                              # set -x tracing
./bin/install --list                               # list available modules
./bin/install --graph                              # show dependency graph
./bin/install --skip-identity                      # Phase 1 (tools) only
./bin/install --skip-modules                       # Phase 2 (git/SSH) only
./bin/install --module=node,neovim                 # specific modules only
./bin/install --skip=bun,starship                  # exclude modules
./bin/install --force                              # ignore completion state
./bin/install --name="..." --email="..." --github="..."  # non-interactive
```

## Module state

```bash
ls ~/.wiz/state/          # see what's marked complete
cat ~/.wiz/state/node     # STATUS, TIMESTAMP, VERSION, DESCRIPTION
rm ~/.wiz/state/node      # force-reset one module (or use --force)
```

## Dev scripts

```bash
./scripts/check_bash_style.sh               # style lint (all .sh files)
./scripts/check_bash_style.sh lib/common.sh # single file
./scripts/test_dry_run.sh                   # dry-run smoke test
./scripts/test_github.sh                    # SSH + GitHub connectivity
./scripts/setup_git_hooks.sh                # install commit-msg hook locally
```

## CI checks (run locally before pushing)

```bash
shellcheck --severity=error bin/install bin/bootstrap lib/**/*.sh lib/modules/*.sh
```

## Commit message format (enforced by hook + CI)

```
<type>(<optional scope>): <description>   # max 100 chars

Types: feat  fix  docs  style  refactor  perf  test  build  ci  chore  revert
```

Examples:
```
feat(module): add install_rust module
fix: prevent chsh hang in non-interactive mode
chore: bump NVM_VERSION to v0.39.7
```

## Adding a new module

1. Create `lib/modules/install_mymodule.sh` — implement `describe_mymodule()`, `install_mymodule()`, `verify_mymodule()`
2. Register it in `DEFAULT_MODULES` array — `bin/install:83`
3. Add its deps to `MODULE_DEPS` map — `lib/module-base.sh:51`

## Key env vars for development

```bash
WIZ_DRY_RUN=1          # preview all commands
WIZ_LOG_LEVEL=0        # DEBUG verbosity
WIZ_STOP_ON_ERROR=0    # continue after module failures
WIZ_FORCE_REINSTALL=1  # ignore state files
WIZ_VERBOSE=1          # extra output
```

## Style rules (enforced by `check_bash_style.sh`)

- Shebang: `#!/usr/bin/env bash`
- Near top: `set -euo pipefail` + `IFS=$'\n\t'`
- Max line length: 80 chars
- Functions need a preceding `# funcname() - description` docstring
- No trailing whitespace
- Quote your variables; use `run()` not bare commands for safety

## Logs and backups

```bash
tail -f logs/install_$(date +%F).log    # live install log
ls ~/.wiz/backups/                       # timestamped file backups
ls ~/.wiz/cache/ssh_fingerprints/        # SSH fingerprint cache
```

## Docs

```
docs/RELEASE.md        # release pre-flight checklist
docs/CHEAT_SHEET.md    # this file
```
