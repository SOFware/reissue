# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.5.3] - Unreleased

## [0.5.2] - 2026-09-17

### Added

- finalize_message option sets the finalize commit subject from the version and date (3716c08)

### Changed

- Finalize commits use the subject "Finalize changelog for VERSION" without the release date (3716c08)

### Fixed

- Shared release workflow retries post-release PR creation up to three times before failing, since the gem is already published and the branch pushed by that point (84bf0da)
