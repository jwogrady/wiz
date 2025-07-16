# WIZ — Terminal Magic

**You've found your guild.**

This project is where terminal wizards from every walk of life, race, and creed unite to resist the ways of the evil GUI.

## What is this?

WIZ is a fully automated environment bootstrapper for terminal-first developers. It provides a modular, repeatable, and idempotent way to:
- Set up your personal environment variables and secrets
- Extract and configure SSH keys
- Clone your dotfiles and project repositories
- Install essential system packages and tools
- Configure git and your shell
- Back up and restore your dotfiles
- Recap what happened and guide you on next steps

## Quick Start

All you need to do is run the installer script. Everything else happens automatically:

```sh
git clone https://github.com/jwogrady/wiz.git wiz && cd wiz && chmod +x install.sh init/*.sh bootstrap/*.sh && ./install.sh
```

- The script will prompt you for any required information (like GitHub username, email, etc.).
- It will set up your environment, install packages, configure git, extract SSH keys, and clone your repos.
- At the end, you'll get a recap and next steps.

## What Happens After Running the Installer?

After running `./install.sh`, you can expect the following:

- **Environment Variables:** A `.env` file will be created in the project root, based on your input or the `.env-example` template. This file contains your GitHub info, dotfiles repo, and key locations.
- **SSH Keys:** Your SSH keys will be extracted and set up for use (location defined in `.env`).
- **Dotfiles:** Your dotfiles repository will be cloned to `~/.backup` and can be restored or symlinked to your home directory.
- **WIZ Repo:** The WIZ repository will be cloned (if not already).
- **System Packages:** Essential and additional tools/packages will be installed for your environment.
- **Git & Shell:** Git will be configured with your details, and your shell will be set up as defined in your dotfiles.
- **Backups:** Your default dotfiles will be backed up to `~/.backup/<MACHINE_NAME>/<DATE>_...` before any changes are made.
- **Recap:** At the end, you'll see a summary of what was done and any next steps.

### File & Directory Locations

- `.env` — Your environment configuration (created or updated by the installer)
- `~/.backup/` — Backups of your original dotfiles and your dotfiles repo
- `~/.ssh/` — Your SSH keys (if extracted)
- `wiz/` — The WIZ project directory

### Customization

- You can pre-populate `.env` by copying `.env-example` and editing it before running the installer, or let the script prompt you interactively.
- The installer is idempotent: you can safely re-run it, and it will skip steps that are already complete (like backups for today).

### Prerequisites

- Bash shell (Linux, macOS, or WSL on Windows)
- Git
- Internet connection

If you encounter any issues, check the output for warnings or errors. You can re-run the installer as needed.

---


## Phase 1: INIT Scripts

| Script              | Purpose                                         |
|---------------------|-------------------------------------------------|
| prompt_env.sh       | Prompts for environment variables and writes .env |
| extract_keys.sh     | Extracts SSH keys from archive                  |
| setup_ssh_agent.sh  | Sets up SSH agent and permissions               |
| clone_dotfiles.sh   | Clones your dotfiles repo to backup             |
| clone_wiz.sh        | Clones the WIZ repo                             |

## Phase 2: BOOTSTRAP Scripts

| Script                  | Purpose                                         |
|-------------------------|-------------------------------------------------|
| update_upgrade.sh       | Updates and upgrades system packages            |
| install_essentials.sh   | Installs essential packages                     |
| install_tools.sh        | Installs additional tools                       |
| load_keys.sh            | Loads SSH or other keys                         |
| configure_git.sh        | Configures Git settings                         |
| backup_default_dots.sh  | Backs up default dotfiles                       |
| source_dotfiles.sh      | Restores/symlinks dotfiles from backup          |
| bootstrap_recap.sh      | Shows recap and welcome message                 |

---

## Security Note

> ⚠️  Your `.env` and backup directories may contain sensitive information and SSH keys. Keep them secure and do not share them.

## Platform Support

- Supported: Linux, macOS, or Windows via WSL (Windows Subsystem for Linux)
- Not supported: Native Windows (outside WSL)

## Dotfiles Restore

To restore or symlink your dotfiles from backup, use the provided `source_dotfiles.sh` script. This will link or copy files from your backup to your home directory as needed.

## .env Sourcing

The `.env` file is created or updated by the installer, but is not automatically sourced by all scripts or your shell. If you want these variables available in your shell, add `source /path/to/wiz/.env` to your shell profile, or source it manually as needed.

## Troubleshooting

- If a step fails, check the terminal output for error messages.
- You can re-run the installer after fixing any issues; it will skip completed steps where possible.
- For persistent issues, review the script overview above to run individual steps manually.

