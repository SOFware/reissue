# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.3.1] - 2025-01-16

### Added

- Add `retain_changelogs` option to control how to retain the changelog files for the previous versions.

### Changed

- Set the name of the `reissue:branch` argument to `branch_name` to be clearer.
- Inject the constants in the `create` method.
- Updated the tested Ruby version to 3.4.

## [0.3.0] - 2024-09-06

### Added

- Add `push_reissue` option to control pushing changes to the remote repository.

### Changed

- Default behavior of _this_ gem's release is to push finalize without a branch.
