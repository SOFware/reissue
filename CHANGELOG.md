# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.1.4] - Unreleased

### Fixed

- Handle changlog files without an empty last line

## [0.1.3] - 2024-06-09

### Added

- Support for alhpa characters in version numbers
- Support for English names for Greek alphabet letters in version numbers

### Fixed

- Reissue.finalize returns the version and value as an array
- Documentation on the refined redo method in Gem::Version
- Limit major numbers to Integers
- Handle empty changelog files
