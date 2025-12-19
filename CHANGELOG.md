# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.4.8] - 2025-12-19

### Fixed

- Inconsistent pluralization of "checksum" vs "checksums" (ed36621)
- Duplicate git trailers documentation in Development section (ed36621)
- clear_fragments task fails when fragment is :git symbol Version: patch (5341aa2)
- Push fails when remote branch exists from previous failed run Version: patch (dab968e)

## [0.4.7] - 2025-12-10

### Fixed

- Git command failures now raise detailed errors with full output (d87ffd3)
- Bundle install skipped when no Gemfile exists in directory (d87ffd3)
- Changelog file configuration ignored in reissue task (35b5a30)

### Added

- Error messages include command, exit status, stdout, and stderr (d87ffd3)

### Changed

- All critical git operations now use comprehensive error checking (d87ffd3)
