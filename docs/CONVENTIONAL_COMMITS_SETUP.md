# Conventional Commits Setup

This repository uses [Conventional Commits](https://www.conventionalcommits.org/) for all commit messages to enable automated versioning and changelog generation.

## Setup

### Automatic Setup (Recommended)

Run the setup script to configure everything:

```bash
./scripts/setup_git_hooks.sh
```

This will:
- Install the commit-msg git hook
- Configure git to use the commit message template
- Verify the setup is working

### Manual Setup

#### 1. Install Git Hook

Copy the commit-msg hook:

```bash
cp .git/hooks/commit-msg.sample .git/hooks/commit-msg
# Or if the hook already exists, ensure it has the correct content
chmod +x .git/hooks/commit-msg
```

The hook should reference `scripts/validate_commit_msg.sh`.

#### 2. Configure Commit Message Template

Set git to use the commit message template:

```bash
git config commit.template .gitmessage
```

Or globally for all repos:

```bash
git config --global commit.template "$(pwd)/.gitmessage"
```

#### 3. Verify Setup

Test that the hook works:

```bash
# This should fail with an invalid message
git commit --allow-empty -m "invalid message"

# This should succeed
git commit --allow-empty -m "chore: test commit message validation"
```

## Commit Message Format

All commit messages must follow this format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Required Fields

- **Type**: One of the valid commit types (see below)
- **Subject**: Brief description (50-72 chars recommended, max 100)

### Optional Fields

- **Scope**: What part of the codebase is affected (e.g., `module`, `install`, `docs`)
- **Body**: Detailed explanation (wrap at 72 chars)
- **Footer**: Reference issues, breaking changes, etc.

### Valid Types

From `commitlint.config.js`:

- `feat`: New feature (triggers MINOR version bump)
- `fix`: Bug fix (triggers PATCH version bump)
- `docs`: Documentation changes
- `style`: Code style (formatting, whitespace)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Build system or external dependencies
- `ci`: CI/CD changes
- `chore`: Maintenance tasks
- `revert`: Reverting a previous commit

### Breaking Changes

For breaking changes, include `BREAKING CHANGE:` in the footer:

```
feat(api)!: redesign command interface

BREAKING CHANGE: The CLI interface has been completely redesigned.
The --old-flag option has been removed. Use --new-option instead.
```

Or use `!` after the type for a breaking change:

```
feat(api)!: redesign command interface
```

## Examples

### Feature

```
feat(starship): add SHA256 verification for installer

Adds SHA256 checksum verification before executing
the Starship installer script for improved security.

Closes #123
```

### Bug Fix

```
fix(install): correct SSH key import path validation

The path validation was incorrectly rejecting valid
Windows paths. Updated regex to properly handle WSL
mount points.

Fixes #456
```

### Documentation

```
docs(style): add Status26 Bash Style Guide v1

Adds comprehensive Bash style guide based on Google
Shell Style Guide. Includes style checker script and
configuration files.

See docs/STATUS26_BASH_STYLE_GUIDE_v1.md
```

### Style/Formatting

```
style(install): fix trailing whitespace and line length

Removes trailing whitespace from all Bash scripts and
fixes lines exceeding 80 character limit per style guide.
```

### Chore

```
chore(deps): update commitlint configuration

Updates commitlint rules to match Status26 standards.
Adds new 'perf' type for performance improvements.
```

## Validation

### Automatic Validation

The git `commit-msg` hook automatically validates all commit messages when you run `git commit`.

### Manual Validation

You can manually validate a commit message:

```bash
# Validate a message file
./scripts/validate_commit_msg.sh .git/COMMIT_EDITMSG

# Validate a specific message
echo "feat: add new feature" | ./scripts/validate_commit_msg.sh
```

### Bypassing Validation

If you need to bypass validation (not recommended):

```bash
git commit --no-verify -m "your message"
```

**Note:** Only use `--no-verify` for exceptional cases. All commits should follow the conventional commits format.

## Integration with Release Process

Conventional commits are used by [Release Please](https://github.com/googleapis/release-please) for automated versioning:

- `feat:` → MINOR version bump (0.X.0)
- `fix:` → PATCH version bump (0.0.X)
- `BREAKING CHANGE:` → MAJOR version bump (X.0.0)
- Other types → No version bump (included in next release)

See `docs/RELEASE.md` for more details on the release process.

## Troubleshooting

### Hook Not Running

If the hook doesn't run:

1. Check that the hook is executable:
   ```bash
   ls -l .git/hooks/commit-msg
   ```

2. Verify the hook exists and has correct content:
   ```bash
   cat .git/hooks/commit-msg
   ```

3. Reinstall the hook:
   ```bash
   ./scripts/setup_git_hooks.sh
   ```

### Validation Fails

If validation fails:

1. Read the error message carefully
2. Check `docs/STATUS26_BASH_STYLE_GUIDE_v1.md` for format guidelines
3. Check `docs/RELEASE.md` for examples
4. Use the commit message template:
   ```bash
   git commit  # Opens editor with template
   ```

### Template Not Showing

If the commit template doesn't show:

1. Check git configuration:
   ```bash
   git config --get commit.template
   ```

2. Set the template:
   ```bash
   git config commit.template .gitmessage
   ```

3. Verify template exists:
   ```bash
   ls -l .gitmessage
   ```

## References

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Status26 Bash Style Guide](STATUS26_BASH_STYLE_GUIDE_v1.md)
- [Release Process](RELEASE.md)
- [Commitlint Configuration](../commitlint.config.js)
