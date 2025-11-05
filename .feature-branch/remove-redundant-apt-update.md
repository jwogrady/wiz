# Feature: Remove Redundant apt-get Update

## Goal
Remove the redundant `apt-get update` call in the neovim module since the essentials module already updates the package cache.

## Implementation Plan

### File to Modify
- `lib/modules/install_neovim.sh` (line 77)

### Changes
1. Remove the `run "sudo apt-get update -y"` line from `install_neovim()`
2. Add a comment explaining why we rely on essentials module's update
3. Keep the error handling for the install command

### Expected Impact
- **Time Saved**: 10-30 seconds per installation
- **Complexity**: Low
- **Risk**: Low (essentials module ensures cache is updated)

### Testing
- Run `./bin/install --module=neovim` and verify it works without apt-get update
- Verify essentials module still updates cache correctly
- Test with `--force` flag to ensure reinstall works

