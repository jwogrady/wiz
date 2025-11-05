# Feature: Skip Descriptions for Completed Modules

## Goal
Skip showing module descriptions for modules that are already completed, reducing terminal clutter and improving user experience.

## Implementation Plan

### File to Modify
- `lib/module-base.sh` (execute_module function)

### Changes
1. Move the `describe_${module_name}` call to after the completion check
2. Only show description if module will actually be installed
3. Keep description for verbose mode or when explicitly requested

### Expected Impact
- **UX Improvement**: Cleaner output, less clutter
- **Time Saved**: 5-10 seconds (minor, but improves readability)
- **Complexity**: Low
- **Risk**: Low

### Testing
- Run `./bin/install` with some modules already installed
- Verify descriptions are skipped for completed modules
- Verify descriptions still show for new modules
- Test with `--force` flag to ensure descriptions show when forcing reinstall

