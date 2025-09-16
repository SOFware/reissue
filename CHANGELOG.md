# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.4.2] - Unreleased

## [0.4.1] - 2025-08-18

### Added

- Add GitHub Actions workflow to release gems with Reissue
- Add `reissue:clear_fragments` task to clear fragments after release
- Add `fragment` configuration option to replace `fragment_directory`

### Changed

- Update README to clarify information about typical usage
- Updated the shared gem release workflow to work with hyphenated gem names.
- Rely on `rubygems/configure-rubygems-credentials` action.
