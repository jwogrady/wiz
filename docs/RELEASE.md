# Release Pre-Flight Checklist

Use this before every release. Work top to bottom. Do not skip steps.

---

## 1. Repo hygiene

- [ ] `git status` — working tree is clean
- [ ] `git log origin/master..HEAD` — no unexpected unpushed commits
- [ ] No `.env`, secrets, or debug artifacts staged
- [ ] `hooks/pre-install.d/` — only `.disabled` examples checked in (no live hooks)

## 2. Version sanity

- [ ] `grep WIZ_VERSION lib/common.sh` matches target version
- [ ] `grep 'version-' README.md` — anchor matches target version
- [ ] `.release-please-manifest.json` — `"."` matches last *released* version (not next)
- [ ] `bash bin/install --version` reports the target version (uses `${WIZ_VERSION}`, not hardcoded)
- [ ] Per-module `MODULE_VERSION` values updated if module logic changed

## 3. Changelog integrity

- [ ] `CHANGELOG.md` top section (`[Unreleased]`) reflects actual commits since last tag
- [ ] No invented features; all bullets map to real commits
- [ ] Previous release section has correct version and approximate date
- [ ] No duplicate bullets

## 4. README accuracy

- [ ] Quick Start `curl` URL points to `master` branch
- [ ] Module table matches actual modules in `lib/modules/`
- [ ] Repository Layout tree matches actual directory structure
- [ ] Tests section lists all `.bats` suites
- [ ] Requirements section lists correct Bash minimum (currently: 4.3+)
- [ ] Environment Variables table matches variables in `lib/common.sh`

## 5. Test gate

```bash
bats tests/          # must be 0 failures
./tests/run_tests.sh --tap | grep -c '^ok'   # must equal total test count
```

- [ ] All tests pass locally
- [ ] CI `Tests` job is green on the release branch

## 6. Installer safety

```bash
# Confirm NVM SHA is set
grep 'NVM_INSTALLER_SHA256' lib/modules/install_node.sh   # must be non-empty

# Confirm SHA matches live installer (update NVM_VERSION first if bumped)
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | sha256sum

# Confirm unknown flags fail
bash bin/install --no-such-flag 2>&1; echo $?   # must exit 2

# Dry-run smoke test
./bin/install --dry-run --skip-identity 2>&1 | grep -i error   # should be empty
```

- [ ] `NVM_INSTALLER_SHA256` is populated and matches live installer
- [ ] Unknown CLI flags exit with code 2
- [ ] `--dry-run` produces no errors and no real changes

## 7. CI / release automation

- [ ] `shellcheck.yml` — no ShellCheck errors on `master`
- [ ] `commitlint.yml` — all commits since last tag follow Conventional Commits
- [ ] `test.yml` — BATS job passes
- [ ] `release-please.yml` — workflow exists and has correct permissions (`contents: write`, `pull-requests: write`)
- [ ] `.release-please-config.json` `extra-files` snippet anchor exists in `README.md`

## 8. Artifact sanity

The `release-please.yml` workflow creates a `git archive` tarball. Verify manually once after a release:

```bash
git archive --format=tar.gz HEAD -o /tmp/wiz-release-test.tar.gz
tar -tzf /tmp/wiz-release-test.tar.gz | grep -E 'bin/|lib/|tests/'
```

- [ ] Archive contains `bin/install`, `bin/bootstrap`, all `lib/` files
- [ ] Archive does not contain `.env`, `logs/`, or `*.disabled` hook files

## 9. Final go/no-go gate

- [ ] All items above checked
- [ ] No open issues tagged `release-blocker`
- [ ] CHANGELOG.md `[Unreleased]` section moved to the new version heading
- [ ] `git tag -a vX.Y.Z -m "Release vX.Y.Z"` (or let release-please do it)

## 10. Post-release verification

```bash
# Confirm tag exists
git tag | grep vX.Y.Z

# Confirm bootstrap installs from correct tag/branch
curl -fsSL https://raw.githubusercontent.com/jwogrady/wiz/master/bin/bootstrap | head -5

# Confirm version is reported correctly
bash -c 'source lib/common.sh 2>/dev/null; echo $WIZ_VERSION'
```

- [ ] GitHub Release page has correct title and changelog body
- [ ] Release asset (`.tar.gz`) downloads and extracts cleanly
- [ ] `./bin/install --version` reports the new version
