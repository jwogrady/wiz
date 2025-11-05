# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2025-11-05

### Added
- **Installation Summary**: Shows clear plan of what will be installed vs skipped before starting
- **Progress Bar with Time Estimation**: Displays elapsed time and ETA for installation progress
- **Enhanced Error Messages**: Context-aware troubleshooting hints for common errors
- **SSH Fingerprint Caching**: Caches SSH key fingerprints for faster subsequent runs
- **Batch Package Installation**: Installs all packages in one efficient batch operation
- **Improved Shell Reload Behavior**: Optional auto-reload via `WIZ_AUTO_RELOAD_SHELL=1` environment variable
- **Comprehensive Documentation**: Added workflow analysis, test results, and user experience guides

### Changed
- **Optimized Package Installation**: Essentials module now installs all packages in single batch (saves 5-15 seconds)
- **Skip Descriptions for Completed Modules**: Cleaner output by skipping verbose descriptions for already-installed modules
- **Removed Redundant Operations**: Eliminated duplicate `apt-get update` calls (saves 10-30 seconds)
- **Better Error Recovery**: More actionable error messages with specific troubleshooting steps
- **Progress Tracking**: Enhanced progress bars with time estimates and clearer status indicators

### Performance
- **Time Savings**: 20-55 seconds saved per installation through optimizations
- **Efficiency**: Reduced apt-get overhead through batch operations
- **Caching**: SSH fingerprint caching improves subsequent run performance

### Documentation
- Added `WORKFLOW_ANALYSIS.md` - Comprehensive analysis of efficiency and UX opportunities
- Added `USER_EXPERIENCE.md` - Complete guide to user experience and journey
- Added `OPTIMIZATIONS_APPLIED.md` - Detailed documentation of all optimizations
- Added `TEST_RESULTS.md` - Test results and verification status
- Added `FEATURE_BRANCHES.md` - Feature branch status and implementation details

## [0.3.0] - Previous Release

### Added
- Documentation and refactoring improvements
- Code review guidelines
- Bash style guide compliance

## [0.2.0] - Previous Release

### Added
- Major refactor and stability improvements
- Module system improvements
- Dependency management

## [0.1.0] - Initial Release

### Added
- Initial release of Wiz - Terminal Magic
- Core module installation system
- Two-phase installation (tools + identity)
- SSH key management
- Git configuration

[0.4.0]: https://github.com/jwogrady/wiz/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/jwogrady/wiz/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/jwogrady/wiz/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/jwogrady/wiz/releases/tag/v0.1.0

