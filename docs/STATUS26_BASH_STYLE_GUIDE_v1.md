# Status26 Bash Style Guide v1

**Based on:** Google Shell Style Guide & easybash/bash-coding-style-guide  

**Adapted for:** Status26 automation, deployment, and marketing infrastructure

---

## Purpose & Scope

This guide defines how Bash scripts must be written at Status26.  

It emphasizes safety, readability, and maintainability over clever hacks.  

Shell is for automation, glue logic, and deployment tasks ≤100 lines.  

If logic becomes complex or data-driven, migrate to Python or Node.js.

---

## Environment & Shebang

```bash
#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'

```

All scripts must:

* Start with this exact shebang.
* Set strict mode immediately after.
* Be executable (`chmod +x`).

---

## Indentation & Layout

* 2 spaces, never tabs.
* Max line length: 80 characters.
* Break long pipelines vertically and align subsequent lines.
* Blank lines contain **no spaces**.
* One blank line between functions.

---

## Variables & Quoting

* Always quote expansions: `"${var}"`, `"$(cmd)"`.
* Use `${var}` syntax consistently.
* Avoid unquoted globs and word splitting.
* Declare constants as `readonly` and `ALL_CAPS`.
* Mutable variables and locals use `snake_case`.
* Use `local` in functions; avoid globals unless deliberate.

---

## Conditionals & Arithmetic

* Use `[[ ... ]]` for tests (not `[ ... ]`).
* Use `(( ... ))` for numeric expressions.
* Prefer explicit comparisons.
* Avoid command substitution inside conditions unless necessary.

---

## Functions

All functions are declared before the main logic:

```bash
main() {
  # logic
}

main "$@"
```

Rules:

* Use verbs in names (`deploy_site`, `backup_db`, `renew_domain`).
* Keep functions ≤30 lines.
* Separate each function with a blank line.
* Each function must include a docstring:

```bash
# deploy_site() - Deploys static sites to S3
# Args: 1=client_name
# Returns: exit code 0 on success
```

---

## Static Analysis

All scripts must pass ShellCheck before merging:

```bash
shellcheck -x script.sh
```

* Zero errors allowed.
* `# shellcheck disable=SCXXXX` only with justification.
* CI must run `shellcheck` and `shfmt -d` or `bashate` to enforce structure.

---

## Logging

All user-visible output goes through controlled log helpers:

```bash
log_info "Deployment started"

log_warn "Missing optional dependency"

log_error "Failed to connect to ${host}"
```

* Use color only when `[[ -t 1 ]]` (interactive terminal).
* Never `echo` directly except for local variable assignments.
* Log to both stdout and a file when possible.

---

## Trap Hygiene

Always define cleanup traps:

```bash
cleanup() {
  rm -f "${tmp_file:-}"
}

trap cleanup EXIT ERR INT
```

* Declare traps once at top-level scope.
* Never override `trap` inside functions.
* Clean up temp files, mounts, or locks reliably.

---

## Export Discipline

```bash
readonly API_URL="https://api.status26.com"

local cache_dir="/tmp/status26"
```

* Only export variables that must be inherited by subprocesses.
* Don't export internal configuration.
* Avoid leaking variables between sourced scripts.
* Prefer explicit variable passing to functions.

---

## Modular Sourcing

All shared logic lives in `lib/` or `modules/` and must be sourced safely:

```bash
if [[ -f "${LIB_DIR}/common.sh" ]]; then
  source "${LIB_DIR}/common.sh"
else
  echo "Missing library: ${LIB_DIR}/common.sh" >&2
  exit 1
fi
```

* Never assume `$PWD` — resolve via `$(dirname "${BASH_SOURCE[0]}")`.
* Keep modules stateless (no global mutation).
* Shared modules define `describe_<name>` and `run_<name>` patterns.
* Validate sourced files exist before loading.

---

## SHA256 Verification

All external downloads must be verified:

```bash
curl -fsS -o /tmp/tool.tar.gz "$url"

echo "${expected_hash}  /tmp/tool.tar.gz" | sha256sum --check -
```

* Reject unverified or unsigned binaries.
* Hardcode or securely fetch expected hashes.
* Never use `curl -k` or `--insecure`.

---

## Portability

* Target **Bash 5.0+** only.
* Do **not** attempt POSIX `/bin/sh` compatibility.
* Use Bash features freely (`[[ ]]`, arrays, `mapfile`, `local`, etc.).

---

## Pipelines & Safety

Split multi-command pipelines vertically:

```bash
mapfile -t clients < <(cat clients.txt |
  grep -v '^#' |
  sort |
  uniq)
```

Always check command exit codes:

```bash
if ! curl -fsS "${url}" -o /tmp/data; then
  echo "Request failed" >&2
  exit 1
fi
```

---

## Error Handling & Security

* Provide descriptive error messages.
* Redirect errors to `stderr` (`>&2`).
* Always clean up temp files via `trap`.
* Never use `eval`.
* Avoid `sudo` inside libraries; only top-level scripts may elevate.
* Use HTTPS for all network operations.
* Validate all remote binaries with checksums.

---

## Comments & Documentation

File header:

```bash
# deploy.sh - Deploys client sites to S3
# Usage: ./deploy.sh [client-name]
```

Inline comments explain *why*, not *what*.

---

## Enforcement

* PRs must pass ShellCheck and `shfmt`.
* CI will fail builds for violations.
* Reviewers enforce structure, logging, and cleanup standards.

---

## Commit Messages

All commits must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```bash
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
* `feat`: New feature
* `fix`: Bug fix
* `docs`: Documentation changes
* `style`: Code style (formatting, whitespace)
* `refactor`: Code refactoring
* `test`: Adding or updating tests
* `chore`: Maintenance tasks
* `ci`: CI/CD changes

**Examples:**
```bash
feat(starship): add SHA256 verification for installer

Adds SHA256 checksum verification before executing
the Starship installer script for improved security.

Closes #123
```

```bash
fix(install): correct SSH key import path validation

The path validation was incorrectly rejecting valid
Windows paths. Updated regex to properly handle WSL
mount points.

Fixes #456
```

**Enforcement:**
* Commitlint validates all commit messages
* See `commitlint.config.js` for configuration
* See `docs/RELEASE.md` for versioning rules

---

## Philosophy

Readability beats clever one-liners.

Consistency beats perfection.

Every script should be safe for another engineer to edit confidently six months later.

---

**Status26 Engineering — v1.0**
