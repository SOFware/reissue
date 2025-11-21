# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.4.5] - 2025-11-21

### Added

- NOTIFY_APP_NAME ENV var for CI runs in 5700751d (e2c75ff)
- Support for alphanumery patch version tag matching in 5c17ce36 (e2c75ff)
- Info in the README about adding trailers in development of Reissue (68117e0)

### Fixed

- Duplicate changelog entries with incorrect release dates. (1e03b68)

## [0.4.4] - 2025-10-17

### Changed

- Derive TRAILER_REGEX from VALID_SECTIONS to eliminate duplication (32b963e)
- Updated example Rakefile to include version trailer configuration (4f2a254)
- Replace Qlty with native SimpleCov coverage reporting in CI (764d6ba)

### Added

- Version trailer parsing methods to GitFragmentHandler (0434f69)
- Version bump rake task with idempotency protection (9ff858a)
- Build task enhancement to process version trailers before finalize (b5a05b7)
- Release flow integration documentation and verification tests (e038230)
- Version bumping documentation to README.md (4f2a254)
- Version trailer examples and usage guide (4f2a254)
- PR comments showing code coverage percentage and threshold status (bfa4619)
- ChatNotifier to update slack about CI runs (55dfeb8)

### Fixed

- Namespace loading problem when building a new release with Gem::Version. (c5fffd0)
