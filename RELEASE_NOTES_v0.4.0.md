# Release v0.4.0 - Performance and UX Optimizations

**Release Date**: November 5, 2025

## 🎉 What's New

This release focuses on **performance optimizations** and **user experience improvements** to make Wiz faster, more transparent, and easier to use.

## ✨ Key Features

### Installation Summary
See exactly what will be installed before starting:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  INSTALLATION PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  📦 Will install:   essentials zsh starship node bun neovim
  Total modules:    6

  ⊘ Will skip:       summary
  Skipped count:    1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Progress Bars with Time
Know how long installation will take:
```
[##################################] 85% [6/7] neovim [02:15 elapsed, ~00:20 remaining]
```

### Enhanced Error Messages
Get actionable troubleshooting hints:
```
✖ Command failed (exit 1): sudo apt-get install -y neovim
  💡 Troubleshooting: Check: sudo apt-get update && sudo apt-get install -f
```

### Batch Package Installation
All packages installed in one efficient operation:
```
→ Installing 50+ packages across all categories...
  Categories: network, monitoring, build, dev, shell, docker, security, editors, github-cli, system
```

## 🚀 Performance Improvements

- **20-55 seconds saved** per installation
- **Batch operations** reduce apt-get overhead
- **SSH fingerprint caching** speeds up subsequent runs
- **No redundant operations** - eliminated duplicate updates

## 🎨 User Experience Enhancements

- **Transparency**: Installation plan shown upfront
- **Time Awareness**: Progress bars show elapsed time and ETA
- **Helpful Errors**: Context-aware troubleshooting hints
- **Cleaner Output**: Skip descriptions for completed modules
- **Respectful UX**: No automatic shell reload (optional via `WIZ_AUTO_RELOAD_SHELL=1`)

## 📚 Documentation

New comprehensive guides:
- `WORKFLOW_ANALYSIS.md` - Efficiency analysis and recommendations
- `USER_EXPERIENCE.md` - Complete UX guide and journey map
- `OPTIMIZATIONS_APPLIED.md` - Detailed optimization documentation
- `TEST_RESULTS.md` - Test verification and status

## 🔧 Technical Details

### New Functions
- `show_installation_summary()` - Pre-installation plan display
- `get_cached_ssh_fingerprint()` - SSH fingerprint caching
- Enhanced `progress_bar()` with time estimation
- Enhanced `error()` with troubleshooting hints

### Optimizations
- Batch package collection in essentials module
- Single apt-get call instead of multiple
- Cached SSH fingerprints in `~/.wiz/cache/ssh_fingerprints/`
- Removed redundant apt-get update in neovim module

## 📦 Installation

```bash
# One-line installation
curl -fsSL https://raw.githubusercontent.com/jwogrady/wiz/main/bin/bootstrap | bash

# Or update existing installation
cd ~/wiz && git pull origin master
```

## 🔄 Migration

**No migration needed!** All changes are backward compatible.

If you want to take advantage of the new features:
1. Pull the latest changes
2. Run `./bin/install` again (it will skip completed modules)
3. Enjoy the improved experience!

## 🐛 Bug Fixes

- Fixed redundant apt-get update calls
- Improved error message clarity
- Better handling of edge cases in module installation

## 📝 Full Changelog

See [CHANGELOG.md](CHANGELOG.md) for complete list of changes.

## 🙏 Acknowledgments

Thank you to all contributors and users who provided feedback that led to these improvements!

---

**Upgrade**: `cd ~/wiz && git pull origin master && git checkout v0.4.0`

**Documentation**: See [README.md](README.md) for full usage guide.

