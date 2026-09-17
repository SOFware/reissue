# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.5.2] - 2026-09-17

### Added

- finalize_message option sets the finalize commit subject from the version and date (3716c08)

### Changed

- Finalize commits use the subject "Finalize changelog for VERSION" without the release date (3716c08)

### Fixed

- Shared release workflow retries post-release PR creation up to three times before failing, since the gem is already published and the branch pushed by that point (84bf0da)

## [0.5.1] - 2026-07-24

### Added

- reissue:next_version task reports the version the next release would use without changing anything (9feb212)
- reissue:initialize[runbook] scaffolds a starter runbook file (dfa521a)

### Changed

- Runbook finalize and new-version reset preserve a custom title and preamble (a0d874c)

### Fixed

- Releases no longer publish a version whose changelog entry and git tag name the previous version (acf4c1a)
