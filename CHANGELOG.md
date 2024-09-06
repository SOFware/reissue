# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.2.3] - Unreleased

## [0.2.2] - 2024-09-06

### Added

- Add a `reissue:branch` task to create a new branch for the next version
- Add a `reissue:push` task to push the new branch to the remote repository

### Fixed

- Require the 'date' library in tests to ensure the Date constant is present
- Ensure that `updated_paths` are always enumerable
