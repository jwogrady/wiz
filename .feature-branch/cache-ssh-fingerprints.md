# Feature: Cache SSH Key Fingerprints

## Goal
Cache SSH key fingerprints to avoid repeated expensive `ssh-keygen -lf` calls, improving performance on subsequent runs.

## Implementation Plan

### Files to Modify
- `bin/install` (load_ssh_keys_to_agent function)
- `lib/common.sh` (add caching helper functions)

### Changes
1. Create cache directory: `~/.wiz/cache/ssh_fingerprints/`
2. Create helper function `get_cached_fingerprint()` that:
   - Checks cache file for fingerprint
   - Compares key file mtime with cache mtime
   - Only runs `ssh-keygen -lf` if cache is stale or missing
   - Saves fingerprint to cache
3. Update `load_ssh_keys_to_agent()` to use cached fingerprints
4. Update `configure_ssh_agent()` shell config to use cached fingerprints

### Expected Impact
- **Performance**: Faster subsequent runs (avoid ssh-keygen calls)
- **Time Saved**: 1-5 seconds per run (depending on number of keys)
- **Complexity**: Medium
- **Risk**: Low (fallback to direct call if cache fails)

### Testing
- Run `./bin/install` and verify cache files are created
- Verify fingerprints are correct
- Test with key file modification (should regenerate cache)
- Test with missing cache (should regenerate)
- Verify cache works in shell startup scripts

