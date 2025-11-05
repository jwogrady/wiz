# SSH Key Management

Wiz automatically imports and manages SSH keys during bootstrap.

## Key Import Priority

The installation script checks for SSH keys in the following order:

1. **Explicit `--keys-path` argument** - If provided via command line
2. **`C:\Users\john\keys.tar.gz`** - Archive file containing `.ssh` directory
3. **`C:\Users\john\keys.tar.gz/.ssh`** - Directory path (if archive is a directory)
4. **Windows user `.ssh` directory** - `/mnt/c/Users/{WIN_USER}/.ssh`
5. **Generate new key** - If no keys found

## Archive Structure

The `keys.tar.gz` archive should contain a `.ssh` directory with your SSH keys:

```
keys.tar.gz
└── .ssh/
    ├── id_vultr
    ├── id_vultr.pub
    ├── id_jwogrady
    ├── id_jwogrady.pub
    └── ... (other keys)
```

## SSH Agent Configuration

SSH keys are automatically loaded into `ssh-agent` when you:
- Start a new shell session (via `.zshrc` or `.bashrc`)
- Run the install script (keys loaded immediately)

All private keys in `~/.ssh/` are automatically loaded, including:
- `id_*` keys (standard naming)
- Named keys like `id_vultr`, `id_jwogrady`, etc.

## Manual Key Import

To manually import keys:

```bash
# Import from archive
./bin/install --keys-path=/mnt/c/Users/john/keys.tar.gz

# Force re-import (overwrite existing)
./bin/install --force --keys-path=/mnt/c/Users/john/keys.tar.gz
```

## Verification

Test SSH key setup:

```bash
# Check keys are present
ls -la ~/.ssh/

# Check keys are loaded in agent
ssh-add -l

# Test GitHub connection
ssh -T git@github.com
```

