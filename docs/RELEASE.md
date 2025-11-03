# Release Process

Wiz uses [Release Please](https://github.com/googleapis/release-please) for automated releases based on conventional commits.

## How It Works

1. **Write commits using conventional commit format:**
   ```
   feat: add new feature
   fix: resolve bug
   docs: update documentation
   chore: update dependencies
   ```

2. **Push to master branch:**
   - Release Please analyzes commit history
   - Determines next version based on commit types
   - Creates/updates a Release PR automatically

3. **Review the Release PR:**
   - Check the generated CHANGELOG.md
   - Verify version bump is correct
   - Review all changes since last release

4. **Merge the Release PR:**
   - Automatically creates a GitHub release
   - Tags the release with the new version
   - Updates CHANGELOG.md
   - Updates version in README.md

## Commit Types and Version Bumping

- `feat:` - **MINOR** version bump (0.X.0)
- `fix:` - **PATCH** version bump (0.0.X)
- `BREAKING CHANGE:` in commit body - **MAJOR** version bump (X.0.0)
- `chore:`, `docs:`, `style:`, `refactor:`, `test:`, `ci:` - No version bump (included in next release)

## Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Examples

**Feature:**
```
feat(modules): add redis installation module

Adds new module to install and configure Redis server
with default configuration for development.

Closes #42
```

**Bug Fix:**
```
fix(starship): correct argument passing to installer

The --yes flag was being passed incorrectly to bash,
causing installation to fail. Changed to use sh -s -- --yes.

Fixes #123
```

**Breaking Change:**
```
feat(cli)!: redesign command-line interface

BREAKING CHANGE: The CLI has been completely redesigned.
- Removed --install-all flag, use --module=all instead
- Changed --skip to --exclude for consistency
- Renamed --dry to --dry-run for clarity

Migration guide added to README.md

Closes #99
```

## Manual Release (if needed)

If you need to create a release manually:

1. Update version in README.md
2. Update CHANGELOG.md
3. Commit changes: `git commit -m "chore(release): prepare vX.Y.Z"`
4. Create tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
5. Push: `git push origin master --tags`

## Viewing Release History

- **GitHub Releases**: https://github.com/jwogrady/wiz/releases
- **CHANGELOG.md**: Local file in repository root
- **Git Tags**: `git tag -l -n9`

## Troubleshooting

**Release PR not created:**
- Ensure commits follow conventional commit format
- Check GitHub Actions workflow runs
- Verify permissions are set correctly in workflow

**Wrong version bump:**
- Review commit types in the release
- Use `feat!:` or `BREAKING CHANGE:` footer for major bumps
- Multiple `feat:` commits will only bump MINOR once

**Release failed:**
- Check GitHub Actions logs
- Verify GitHub token has correct permissions
- Ensure no merge conflicts in Release PR

## Configuration Files

- `.github/workflows/release-please.yml` - GitHub Actions workflow
- `.release-please-config.json` - Release Please configuration
- `.release-please-manifest.json` - Current version tracking
- `commitlint.config.js` - Commit message linting rules
- `CHANGELOG.md` - Auto-generated changelog

## Best Practices

1. **Write descriptive commit messages** - They become your release notes
2. **Use conventional commits consistently** - Enables automation
3. **Review Release PRs carefully** - This is your last chance to edit before release
4. **Keep CHANGELOG.md clean** - Edit Release PR if needed
5. **Document breaking changes** - Always include migration guide
6. **Test before merging Release PR** - Run `./bin/install --dry-run`

## Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Release Please Documentation](https://github.com/googleapis/release-please)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
