# Wiz - User Experience Guide

## Overview

Wiz provides a **streamlined, transparent, and user-friendly** installation experience with clear visual feedback, helpful error messages, and comprehensive progress tracking.

---

## 🚀 Getting Started

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/jwogrady/wiz/main/bin/bootstrap | bash
```

**User sees:**
```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   🌌  WIZ - TERMINAL MAGIC  ✨                            ║
║                                                            ║
║   Complete Installation (Phase 1: Tools + Phase 2: Identity) ║
║   https://github.com/jwogrady/wiz                          ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

→ Starting Wiz bootstrap (Phase 1: Tools + Phase 2: Identity)...
→ Cloning Wiz repository...
✓ Repository cloned to ~/wiz
```

**Experience:**
- Clear branding and welcome message
- Automatic SSH key detection and import (if available)
- Transparent repository cloning process
- Helpful status messages with color coding

---

## 📋 Installation Plan (New!)

Before anything happens, users see exactly what will be installed:

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

**User Benefits:**
- ✅ **Transparency**: Know exactly what will happen before it starts
- ✅ **No Surprises**: See what's already installed vs what's new
- ✅ **Confidence**: Understand the scope of changes

---

## ⚙️ Phase 1: Development Tools Installation

### Module Installation Flow

**For NEW modules (not yet installed):**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ STARSHIP PROMPT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This module installs Starship with the Cosmic Oasis preset:

  🚀 Fast & Minimal:     Written in Rust, blazing fast
  🎨 Cosmic Oasis:       Custom gradient theme with polished appearance
  🐚 Cross-Shell:        Works in Zsh, Bash, Fish, etc.
  ⚙️  Smart Context:      Shows git, node, bun, rust, golang info
  🎯 Customizable:       TOML-based configuration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Module: starship
Version: 0.2.0
Description: Starship cross-shell prompt with Cosmic Oasis preset
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

→ Installing Starship prompt...
⋯ Downloading Starship installer...
✓ Starship installed: v1.20.0
→ Configuring Starship with Cosmic Oasis preset...
✓ Cosmic Oasis preset installed
→ Configuring shell integration...
✓ Shell integration configured
✓ Module completed: starship
```

**For COMPLETED modules (already installed):**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Module: node
Version: 0.2.0
Description: Node.js LTS via NVM with shell integration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

→ Skipping node: Already completed (use WIZ_FORCE_REINSTALL=1 to override)
```

**User Benefits:**
- ✅ **Clean Output**: Only see descriptions for modules that will actually install
- ✅ **No Clutter**: Completed modules skip verbose descriptions
- ✅ **Clear Status**: Know exactly what's happening vs what's being skipped

---

## 📊 Progress Tracking

### Visual Progress Bar with Time

```
[##################################] 85% [6/7] neovim [02:15 elapsed, ~00:20 remaining]
```

**User Benefits:**
- ✅ **Visual Feedback**: See progress at a glance
- ✅ **Time Awareness**: Know how long it's taken and how much remains
- ✅ **Confidence**: Understand the installation is progressing normally

**Progress Bar Features:**
- Color-coded (blue bars)
- Percentage complete
- Current module name
- Elapsed time (MM:SS format)
- Estimated time remaining (based on average module time)

---

## 🎯 Batch Package Installation

### Efficient Package Management

When installing essentials:

```
→ Installing 50+ packages across all categories...
  Categories: network, monitoring, build, dev, shell, docker, security, editors, github-cli, system
→ Installing 45 packages: git curl wget jq tree build-essential ...
```

**User Benefits:**
- ✅ **Faster**: Single batch installation vs multiple separate calls
- ✅ **Transparent**: See exactly what categories are being installed
- ✅ **Efficient**: Reduced overhead from multiple apt-get processes

---

## ⚠️ Error Handling & Troubleshooting

### Enhanced Error Messages

**When a command fails:**

```
✖ Command failed (exit 1): sudo apt-get install -y neovim
  💡 Troubleshooting: Check: sudo apt-get update && sudo apt-get install -f
```

**When a module fails:**

```
✖ Module execution failed: node
  💡 Troubleshooting: Try: ./bin/install --module=node --verbose --debug
```

**When a module is not found:**

```
✖ Module not found: invalid
  💡 Troubleshooting: Available modules: essentials zsh starship node bun neovim summary
```

**User Benefits:**
- ✅ **Actionable**: Get specific steps to resolve issues
- ✅ **Context-Aware**: Hints tailored to the type of error
- ✅ **Self-Service**: Can often fix issues without additional help

---

## 🔄 Phase 2: Identity & SSH Setup

### Git Identity Configuration

**Interactive Mode:**

```
━━━ PHASE 2: Identity & SSH Setup ━━━

→ Enter your full name (for Git commits): John Doe
→ Enter your email (for Git commits): john@example.com
→ Enter your GitHub username: johndoe
✓ Configuration saved to .env
```

**Non-Interactive Mode:**

```bash
./bin/install --name="John Doe" --email="john@example.com" --github="johndoe"
```

**User Benefits:**
- ✅ **Flexible**: Interactive or non-interactive
- ✅ **Validated**: Input validation ensures correct format
- ✅ **Persistent**: Configuration saved for future use

### SSH Key Management

**Automatic Import:**

```
→ Importing SSH keys from Windows for repository access...
→ Importing SSH keys from archive: /mnt/c/Users/john/keys.tar.gz
✓ SSH keys imported from archive
→ Configuring ssh-agent...
✓ SSH agent configured
```

**User Benefits:**
- ✅ **Automatic**: Detects and imports keys from Windows (WSL)
- ✅ **Smart Priority**: Checks multiple locations automatically
- ✅ **Secure**: Proper permissions and agent configuration

---

## ✅ Completion Experience

### Installation Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  INSTALLATION STATISTICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Total modules:    7
  ✓ Completed:      6
  ⊘ Skipped:        1
  ✖ Failed:         0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🌌 WIZ INSTALLATION COMPLETE! ✨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

→ Next steps:
  1. Review configuration files in ~/.config/
  2. Check installed tools: git, docker, nvim, node, etc.

→ ✨ Installation complete!
→ To apply all changes, restart your terminal or run:
  exec zsh  (or exec bash)

→ Shell will not auto-reload. Restart manually to apply changes.
```

**User Benefits:**
- ✅ **Clear Summary**: See exactly what was installed
- ✅ **No Surprises**: Shell doesn't auto-reload (better UX)
- ✅ **Clear Next Steps**: Know exactly what to do next
- ✅ **Optional Auto-Reload**: Can enable with `WIZ_AUTO_RELOAD_SHELL=1`

---

## 🎨 Visual Design

### Color Coding

- **Green (→)**: Informational messages, normal progress
- **Blue (⋯)**: Progress indicators, download status
- **Yellow (⚠)**: Warnings, non-critical issues
- **Red (✖)**: Errors, critical failures
- **Bold Green (✓)**: Success messages, completions
- **Bold**: Important instructions, emphasis

### Typography

- **Unicode Box Drawing**: Clean section separators
- **Emojis**: Visual indicators for module types (📦 🚀 🎨)
- **Consistent Formatting**: All modules follow same structure

**User Benefits:**
- ✅ **Scannable**: Easy to find important information
- ✅ **Professional**: Clean, modern appearance
- ✅ **Accessible**: Clear visual hierarchy

---

## 🔍 Advanced Features

### Dry-Run Mode

```bash
./bin/install --dry-run
```

**Shows:**
```
[DRY-RUN] sudo apt-get install -y git curl wget
[DRY-RUN] curl -sS https://starship.rs/install.sh | sh -s -- --yes
```

**User Benefits:**
- ✅ **Safe Preview**: See what would happen without making changes
- ✅ **Testing**: Verify configuration before running
- ✅ **Learning**: Understand what the installer does

### Verbose & Debug Modes

```bash
./bin/install --verbose    # Show detailed output
./bin/install --debug      # Show shell tracing (set -x)
```

**User Benefits:**
- ✅ **Troubleshooting**: Detailed information for debugging
- ✅ **Transparency**: See every command executed
- ✅ **Learning**: Understand installation process deeply

### Selective Installation

```bash
./bin/install --module=node,neovim    # Install specific modules
./bin/install --skip=starship,bun      # Skip specific modules
./bin/install --list                   # List all modules
./bin/install --graph                  # Show dependency graph
```

**User Benefits:**
- ✅ **Flexible**: Install only what you need
- ✅ **Fast**: Skip unnecessary modules
- ✅ **Informed**: See dependencies and relationships

---

## 📈 Performance Experience

### Time Savings

**Before Optimizations:**
- Multiple apt-get calls: ~2-3 minutes
- Redundant operations: ~30 seconds
- No progress time info: User uncertainty

**After Optimizations:**
- Single batch installation: ~1-2 minutes (saves 30-60s)
- No redundant operations: Saves 10-30s
- Time estimation: Users know how long it takes

**Total Time Saved: 40-90 seconds per installation**

### Perceived Performance

- **Progress bars with ETA**: Users feel installation is faster
- **Clear feedback**: No "is it stuck?" moments
- **Batch operations**: Fewer pauses and delays

---

## 🎯 Key UX Principles Applied

### 1. **Transparency**
- Users see exactly what will happen before it starts
- Clear installation plan with module counts
- Detailed progress tracking

### 2. **Feedback**
- Real-time progress indicators
- Color-coded status messages
- Time estimates for completion

### 3. **Error Recovery**
- Actionable error messages
- Troubleshooting hints
- Clear next steps

### 4. **Respect for User**
- No surprising shell reloads
- Optional auto-reload
- Clear instructions

### 5. **Efficiency**
- Batch operations where possible
- Skip unnecessary work
- Cache where appropriate

### 6. **Flexibility**
- Multiple installation modes
- Selective module installation
- Non-interactive options

---

## 🚦 User Journey Map

### First-Time User

1. **Discovery**: Finds one-line install command
2. **Bootstrap**: Runs curl | bash, sees welcome banner
3. **Plan Review**: Sees installation plan, understands scope
4. **Installation**: Watches progress with time estimates
5. **Configuration**: Sets up Git identity (if needed)
6. **Completion**: Sees summary, gets next steps
7. **Success**: Has fully configured development environment

### Returning User

1. **Update**: Runs `./bin/install` again
2. **Quick Check**: Sees "Will skip: all modules" (already installed)
3. **Fast**: Installation completes in seconds
4. **Confirmation**: Sees summary confirming everything is current

### Troubleshooting User

1. **Issue**: Encounter error during installation
2. **Help**: Error message provides troubleshooting hint
3. **Resolution**: Follows hint, resolves issue
4. **Retry**: Continues installation successfully

---

## 💡 User Experience Highlights

### What Users Love

✅ **Clear Communication**: Always know what's happening  
✅ **Time Awareness**: Know how long it will take  
✅ **Helpful Errors**: Get actionable guidance when things fail  
✅ **No Surprises**: Shell doesn't auto-reload unexpectedly  
✅ **Fast**: Optimized batch operations save time  
✅ **Flexible**: Install only what you need  
✅ **Professional**: Clean, modern interface  

### Improvement Over Previous Version

**Before:**
- ❌ No installation plan (surprises)
- ❌ Redundant operations (wasted time)
- ❌ Generic error messages (unhelpful)
- ❌ No time estimates (uncertainty)
- ❌ Auto-reload shell (surprising)

**After:**
- ✅ Installation plan shown upfront
- ✅ Batch operations (efficient)
- ✅ Context-aware error hints (helpful)
- ✅ Time estimates with ETA (informed)
- ✅ Optional auto-reload (respectful)

---

## 📊 User Experience Metrics

### Clarity
- **Installation Plan**: Shows what will happen before starting
- **Progress Tracking**: Visual bars with percentage and time
- **Error Messages**: Include actionable troubleshooting hints

### Efficiency
- **Batch Operations**: Single call for package installation
- **Smart Skipping**: Only install what's needed
- **Caching**: SSH fingerprints cached for speed

### Satisfaction
- **No Surprises**: Transparent process
- **Helpful**: Error messages guide resolution
- **Professional**: Clean, modern interface

---

## 🎓 Best Practices Demonstrated

1. **Progressive Disclosure**: Show information when needed
2. **Feedback Loops**: Always show progress
3. **Error Prevention**: Validate inputs, check dependencies
4. **Error Recovery**: Provide clear next steps
5. **Performance**: Optimize for speed and efficiency
6. **Accessibility**: Color coding, clear text, visual indicators

---

## Conclusion

Wiz provides a **world-class user experience** for setting up development environments:

- **Transparent**: Users always know what's happening
- **Efficient**: Optimized for speed and performance  
- **Helpful**: Clear guidance and error recovery
- **Respectful**: No surprising behavior, clear choices
- **Professional**: Clean interface and consistent design

The result is a **delightful installation experience** that users trust and enjoy using.

