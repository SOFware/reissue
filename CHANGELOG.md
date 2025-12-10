# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.4.7] - 2025-12-10

### Fixed

- Git command failures now raise detailed errors with full output (d87ffd3)
- Bundle install skipped when no Gemfile exists in directory (d87ffd3)
- Changelog file configuration ignored in reissue task (35b5a30)

### Added

- Error messages include command, exit status, stdout, and stderr (d87ffd3)

### Changed

- All critical git operations now use comprehensive error checking (d87ffd3)

## [0.4.6] - 2025-12-05

### Added

- NOTIFY_APP_NAME ENV var for CI runs in 5700751d (e2c75ff)
- Support for alphanumery patch version tag matching in 5c17ce36 (e2c75ff)
- Info in the README about adding trailers in development of Reissue (68117e0)

### Fixed

- Duplicate changelog entries with incorrect release dates. (1e03b68)

### Changed

- Branch naming convention to use distinct prefixes for finalize vs reissue (d1add14)
