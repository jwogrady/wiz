# Tests

Unit tests for the Wiz library functions using [BATS](https://github.com/bats-core/bats-core)
(Bash Automated Testing System).

## Install BATS

```bash
sudo apt-get install bats         # Debian/Ubuntu
brew install bats-core            # macOS
npm install -g bats               # anywhere
```

## Run

```bash
# All suites
./tests/run_tests.sh

# TAP output (useful for CI)
./tests/run_tests.sh --tap

# Single suite
./tests/run_tests.sh tests/test_has_ssh_keys.bats
```

## Suites

| File | Tests |
|------|-------|
| `test_parse_state_value.bats` | `_parse_state_value()` — key lookup in state files |
| `test_is_module_complete.bats` | `is_module_complete()` / `get_module_state()` — state transitions |
| `test_get_install_order.bats` | `get_install_order()` — topological sort, diamond deps, circular detection |
| `test_has_ssh_keys.bats` | `has_ssh_keys()` — directory content classification |
| `test_wiz_download_verified.bats` | `wiz_download_verified()` — download + SHA-256 verification |
| `test_wiz_add_shell_block.bats` | `wiz_add_shell_block()` — shell rc-file block append |
| `test_wiz_update_shell_block.bats` | `wiz_update_shell_block()` — shell rc-file block replace |

## Adding a New Suite

1. Create `tests/test_<name>.bats`.
2. Load the shared helper at the top:
   ```bash
   load helpers/common_setup
   setup()    { _common_setup;    source "${WIZ_ROOT}/lib/<target>.sh"; }
   teardown() { _common_teardown; }
   ```
3. Write `@test` blocks. Use `bats_run` for functions whose exit code you want to
   assert; use direct calls for output capture.
   **Note:** `run` is clobbered by wiz's `run()` wrapper when any wiz library is
   sourced. Always use `bats_run` (aliased in `_common_setup`) in test files.

## Test Helper (`helpers/common_setup.bash`)

`_common_setup` stubs all `WIZ_*` environment variables and creates an
isolated temp directory (`$TEST_TMPDIR`). State files, log files, and SSH
fixture dirs are all created under `$TEST_TMPDIR`.

`_common_teardown` removes `$TEST_TMPDIR` and closes the persistent log FD
opened by `common.sh` (prevents "bad file descriptor" warnings from BATS).

Note: `.bats` files use BATS preprocessor syntax (`@test`, `run`) which is
not valid raw Bash. Do not lint them with `bash -n`.
