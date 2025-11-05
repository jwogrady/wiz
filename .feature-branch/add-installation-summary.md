# Feature: Add Installation Summary

## Goal
Show users a clear summary of what will be installed before starting, improving transparency and user experience.

## Implementation Plan

### File to Modify
- `bin/install` (run_module_installation function)

### Changes
1. After dependency resolution, analyze which modules will install vs skip
2. Display a clear summary showing:
   - Modules that will be installed (new)
   - Modules that will be skipped (already completed)
   - Optional: Estimated time (if we track module times)
3. Optionally ask for confirmation (unless --yes or --non-interactive flag)

### Expected Impact
- **UX Improvement**: Users know what will happen before it starts
- **Transparency**: Clear visibility into installation plan
- **Complexity**: Medium
- **Risk**: Low

### Testing
- Run `./bin/install` and verify summary shows correctly
- Test with `--skip=module` and verify summary reflects it
- Test with `--module=module` and verify summary shows only requested modules
- Test with already-installed modules and verify they appear in "skip" list

