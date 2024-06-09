# Change log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.1.1] - Unreleased

### Added:

- bundle install when running reissue
- handling of brackets in the changelog version numbers
- Reissue::Parser class to parse the changelog file
- Reissue::Printer class to print the changelog file
- Reissue::Task class to handle the creation of reissue tasks
- Return version and date from Reissue.finalize

### Fixed:

- bug in tests loading the changelog fixture
- format of the changelog file

### Removed:

- dependency on the keepachangelog gem

## [0.1.0] - 2024-04-11

### Added:

- Initial release
