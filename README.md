
# Wiz - Terminal Magic

![OS](https://img.shields.io/badge/OS-WSL%20%7C%20Linux-blue)
![Shell](https://img.shields.io/badge/Shell-bash%20%7C%20zsh-brightgreen)
![Idempotent](https://img.shields.io/badge/Idempotent-Yes-success)
![Extensible](https://img.shields.io/badge/Extensible-Yes-blueviolet)
![License](https://img.shields.io/badge/License-MIT-yellow)



**Wiz** is a fast, modular, and user-friendly Bash-based developer environment bootstrapper for WSL/Unix systems. It automates:
- Git identity and SSH key setup
- Global Git configuration
- Installation of popular developer tools, editors, and shell enhancements

Wiz is designed for:
- **Speed**: Minimal prompts, parallelized where safe, and idempotent for repeated runs
- **Simplicity**: Clear, color-coded output and easy onboarding
- **Extensibility**: Add your own modules and post-install hooks
- **Reliability**: Automated dotfile backup and robust error handling


## Features
- One-script onboarding for new dev machines
- Modular install scripts for each tool/stack
- Centralized logging, error handling, and atomic config writes
- Idempotent and safe for repeated runs
- Extensible via user hooks and custom modules
- Automated backup of user dotfiles
- Color-coded, clear output and robust error handling
- Automated tests for idempotency and utilities


## 🚀 Quick Start

1. **Download and run the installer:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/jwogrady/wiz/refs/heads/master/install.sh -o install.sh
   bash install.sh
   ```
2. **Follow the prompts** for Git identity, SSH keys, and repo setup.
3. **After install.sh completes:**
   ```bash
   cd ~/wiz/init
   ./bootstrap.sh
   ```
   This will install all developer tools and finish your environment setup.

**Re-run anytime:** All scripts are safe for repeated use.

## 📁 Directory Structure
```
wiz/
├── install.sh                # Entry point for identity, SSH, and repo setup
├── init/
│   ├── bootstrap.sh          # Orchestrates all module installs, sources aliases, runs backup, and post-install hooks
│   ├── aliases.sh            # Shell aliases
│   └── modules/              # One script per tool/stack for modular, maintainable installs
│       ├── install_essentials.sh
│       ├── install_shellcheck.sh
│       ├── install_neovim.sh
│       ├── install_node.sh
│       ├── install_bun.sh
│       ├── install_starship_zsh.sh
│       ├── install_hostmaster_tools.sh
│       ├── install_system_specs_tools.sh
│       ├── install_docker.sh
│       ├── install_openai_cli.sh
│       ├── install_github_cli.sh
│       └── ...
├── scripts/
│   └── backup.sh             # Backs up user dotfiles
├── lib/
│   └── common.sh             # Shared logging, error handling, atomic write, and utility functions
├── hooks/
│   └── post_install_custom.sh# User-defined post-install steps
├── tests/
│   ├── test_common.sh        # Automated tests for utilities
│   └── test_idempotency.sh   # Automated tests for idempotency
├── docs/
│   ├── README.md
│   ├── USAGE.md
│   ├── TECHNICAL.md
│   ├── CHANGELOG.md
│   └── PROMPT.md
```


## ⚙️ Configuration
- `.env` in your home directory stores your identity and environment variables
- `.gitconfig` and `.gitignore_global` are set up in your home directory
- SSH keys are managed in `~/.ssh/`


## 🤝 Contributing
- Fork the repo and create a feature branch
- Submit pull requests with clear descriptions
- Report issues via GitHub Issues
- Follow Bash best practices and keep scripts modular and idempotent


## 🏷️ Versioning
This project follows [Semantic Versioning 2.0.0](https://semver.org/):
- **MAJOR** version when you make incompatible API or workflow changes
- **MINOR** version when you add functionality in a backward-compatible manner
- **PATCH** version when you make backward-compatible bug fixes

Version is tracked in the `CHANGELOG.md` and git tags (e.g., `v0.1.0`).

## 📝 Commit Standards
All commits should use structured, conventional messages for clarity and automation:

- **Format:** `<type>(<scope>): <short description>`
- **Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- **Example:**
  - `feat(bootstrap): add parallel install for modules`
  - `fix(common): correct atomic_write logic for empty files`
  - `docs(readme): add semantic versioning section`

See [Conventional Commits](https://www.conventionalcommits.org/) for more details.


## 🛠️ Troubleshooting

If you encounter issues, try the following:

- **Missing dependencies:** Ensure `git`, `ssh-agent`, `tar`, `curl`, and `sudo` are installed and available in your PATH.
- **SSH key problems:** Confirm your SSH key archive is accessible and in the expected format. Check permissions on `~/.ssh/` and key files.
- **Permission errors:** Run scripts as your user, not root. Use `sudo` only when prompted.
- **Idempotency:** All scripts are safe to re-run. If something fails, fix the issue and re-run the script.
- **Environment variables:** Check your `.env` file for correct values and formatting.
- **Still stuck?** Open an issue on GitHub with details and logs.

## 📚 Documentation

- [README.md](README.md): Project overview, features, and quick start
- [USAGE.md](docs/USAGE.md): End user usage guide and troubleshooting
- [TECHNICAL.md](docs/TECHNICAL.md): Technical architecture and script interactions
- [CHANGELOG.md](docs/CHANGELOG.md): Release history and versioning
- [PROMPT.md](docs/PROMPT.md): Developer, user, and system prompts

## 🪪 License
MIT License. See [LICENSE](LICENSE) for details.
