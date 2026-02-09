# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.4.12] - 2026-02-09

### Changed

- reissue:bump now reads Version trailers regardless of whether the version file matches the last tag (98905d6)

## [0.4.11] - 2026-02-06

### Added

- reissue:initialize task to create changelog and show setup instructions (ad4ae54)
- working_directory input for monorepo gem releases (55dea65)
- Gem integration tests for checksums in updated_paths (16b801e)

### Changed

- Replace rubygems/release-gem action with explicit release steps (55dea65)

### Fixed

- Finalize task fails when changelog is already committed (307939e)
- Checksums not staged during finalize task (307939e)
- Stage updated_paths fails when files do not exist (16b801e)
- Release workflow fails with working-directory command not found (9068f04)
