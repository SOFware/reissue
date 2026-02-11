# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.4.14] - 2026-02-11

### Added

- Reissue.changelog_sections accessor with configurable, ordered section list (3da8a89)
- changelog_sections option to Rake task and Hoe plugin (3da8a89)

### Changed

- DirectoryFragmentHandler and GitFragmentHandler use centralized sections instead of their own constants (3da8a89)

## [0.4.13] - 2026-02-10

### Added

- Hoe plugin for integrating Reissue into Hoe-based projects (f5dde22)
- Hoe plugin usage documentation in README and reissue:initialize task output (2bbd4ea)
