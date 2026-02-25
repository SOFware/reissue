# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.4.18] - 2026-02-25

### Added

- RELEASE_DATE constant tracking in VersionUpdater (496ec6b)
- Reset RELEASE_DATE to Unreleased when bumping version via Reissue.call (a7894cc)
- Update RELEASE_DATE to actual date during Reissue.finalize (8253796)
- RELEASE_DATE to the version.rb (6e08782)

### Changed

- Pass version_file to Reissue.finalize from rake task (83682ff)

## [0.4.17] - 2026-02-24

### Fixed

- Forward tag_pattern to git fragment handler in call and finalize (dd35249)
