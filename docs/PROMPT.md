
# Wiz - Terminal Magic: Combined Prompts and Guidance
# ------------------------------------------------------------------------------
# This document provides:
# - Developer optimization objectives and deliverables
# - End user onboarding and usage instructions
# - System/environment requirements and standards
# ------------------------------------------------------------------------------


## Developer Optimization Prompt

You are tasked with designing and implementing an optimized version of the Wiz project, a Bash-based developer environment bootstrapper for WSL/Unix systems. The project provides interactive setup for Git identity, SSH keys, global configuration, and automated installation of developer tools, editors, and shell enhancements.

### Objectives

- **Performance & Efficiency:**
  - Minimize setup time (reduce redundant package updates, parallelize where safe, avoid unnecessary downloads).
  - Reduce user prompts by auto-detecting values and supporting non-interactive/CI modes.
  - Optimize file operations (only write config files if content changes, use atomic writes).
- **Modularity & Maintainability:**
  - Refactor scripts into modular, reusable components or functions.
  - Split large scripts into smaller, purpose-driven modules or use a task runner.
  - Centralize logging, error handling, and common utilities.
- **Portability & Compatibility:**
  - Support a wide range of Linux distributions (not just Ubuntu/WSL).
  - Detect and adapt to different shells (bash, zsh, etc.) and environments.
  - Parameterize paths and allow for custom install locations.
- **User Experience:**
  - Provide clear, concise, and color-coded output.
  - Support both interactive and fully automated (headless) installs.
  - Offer detailed progress reporting and error diagnostics.
- **Extensibility:**
  - Make it easy to add new tools, editors, or configuration steps.
  - Support user-defined post-install hooks or customizations.
- **Documentation & Testing:**
  - Maintain comprehensive documentation (README, USAGE, TECHNICAL).
  - Add automated tests or validation steps for critical functions.
  - Document all environment variables, config files, and expected user actions.


#### Deliverables
- Refactored and optimized scripts (or a new toolchain) that meet the above goals.
- Updated documentation reflecting all changes and new usage patterns.
- A changelog summarizing optimizations, new features, and breaking changes.
- (Optional) Benchmarks or metrics demonstrating performance improvements.

#### Versioning & Commit Standards
- This project uses [Semantic Versioning 2.0.0](https://semver.org/). Update the version in `CHANGELOG.md` and tag releases (e.g., `v0.1.0`).
- All commits should follow [Conventional Commits](https://www.conventionalcommits.org/) for clarity and automation:
  - Format: `<type>(<scope>): <short description>`
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
  - Example: `feat(bootstrap): add parallel install for modules`

#### Reference Materials
- Review the current `USAGE.md` and `TECHNICAL.md` for workflow, user experience, and architecture.
- Examine the codebase for areas of technical debt, repeated logic, or bottlenecks.
- Consider feedback from end users and contributors for pain points and feature requests.

**Your optimized version should be robust, maintainable, and ready for both individual developers and team onboarding at scale.**

---

## User Prompt: Getting Started with Wiz

Welcome to Wiz, the automated developer environment bootstrapper for WSL/Unix systems.

### What you need to do

1. **Download and run the installer:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/jwogrady/wiz/refs/heads/master/install.sh -o install.sh
   bash install.sh
   ```
2. **Follow the prompts:**
   - Enter your Git name, email, and GitHub username.
   - Confirm or edit your Windows username (for WSL users).
   - Provide or confirm your SSH key archive location.
3. **After install.sh completes:**
   - You will see instructions similar to:
     ```
     1. cd ~/wiz/init
     2. ./bootstrap.sh
     ```
   - Run these commands to continue.
4. **Run the bootstrap script:**
   ```bash
   cd ~/wiz/init
   ./bootstrap.sh
   ```
   - This will install all developer tools, editors, runtimes, and shell enhancements via modular scripts.
   - The script will also source helpful aliases, run a backup of your dotfiles, and execute any post-install hooks.

#### What to Expect
- Prompts for identity and SSH info.
- Key deletion notice after setup.
- Backups of your dotfiles.
- Useful shell aliases and post-install hooks.

For troubleshooting and more details, see the [USAGE.md](USAGE.md) guide.

---

## System Prompt: Wiz Project Environment

This project is designed to be modular, idempotent, and extensible for both individual and team onboarding. All scripts should:

- Be safe for repeated runs (idempotent)
- Use centralized logging and error handling from `lib/common.sh`
- Support both interactive and non-interactive (headless/CI) modes
- Detect and adapt to the current OS and shell
- Parameterize paths and allow for custom install locations
- Orchestrate all install modules from `init/modules/` in the correct order
- Source aliases and run backup scripts
- Support user-defined post-install hooks in `hooks/`
- Provide clear, color-coded output and actionable error messages

For more details, see [TECHNICAL.md](TECHNICAL.md) and [STRUCTURE.md](STRUCTURE.md).
