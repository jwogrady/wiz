# Wiz Hooks System

Hooks allow you to extend wiz with custom scripts that run at specific points during installation.

## Hook Directories

| Directory | When it runs | Arguments |
|-----------|--------------|-----------|
| `pre-install.d/` | Before module installation begins | None |
| `post-install.d/` | After all modules complete | None |
| `pre-module.d/` | Before each module runs | `$1` = module name |
| `post-module.d/` | After each module completes successfully | `$1` = module name |

## Creating a Hook

1. Create an executable script in the appropriate directory
2. Name it with a numeric prefix for ordering (e.g., `01-setup.sh`)
3. Make it executable: `chmod +x hooks/pre-install.d/01-setup.sh`

## Example Hooks

### Pre-install: Check disk space

```bash
#!/usr/bin/env bash
# hooks/pre-install.d/01-check-disk.sh
set -euo pipefail

MIN_SPACE_GB=5
available=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')

if (( available < MIN_SPACE_GB )); then
    echo "ERROR: Less than ${MIN_SPACE_GB}GB disk space available"
    exit 1
fi

echo "Disk space check passed: ${available}GB available"
```

### Post-module: Send notification

```bash
#!/usr/bin/env bash
# hooks/post-module.d/01-notify.sh
set -euo pipefail

module="$1"
echo "Module completed: $module" >> ~/.wiz/install.log

# Optional: Send desktop notification
if command -v notify-send &>/dev/null; then
    notify-send "Wiz" "Module installed: $module"
fi
```

### Pre-module: Skip on certain conditions

```bash
#!/usr/bin/env bash
# hooks/pre-module.d/01-skip-docker-in-ci.sh
set -euo pipefail

module="$1"

# Skip docker module in CI environments
if [[ "$module" == "docker" ]] && [[ -n "${CI:-}" ]]; then
    echo "Skipping docker module in CI environment"
    exit 0
fi
```

## Notes

- Hooks run in alphabetical order within each directory
- Non-executable files are skipped
- Hook failures are logged but don't stop installation (warning only)
- In dry-run mode, hooks are shown but not executed
- Hooks inherit the wiz environment (all exported functions available)
