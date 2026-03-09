# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.4.20] - Unreleased

## [0.4.19] - 2026-03-09

### Added

- Support parsing changelog version entries without a date field (e.g. ## [Unreleased]) (75c5d6c)
- Print ## [Unreleased] without trailing date suffix when version is Unreleased (aed6011)
- ChangelogUpdater handles Unreleased version strings without crashing (d5f4e3e)
- ChangelogUpdater#finalize accepts resolved_version parameter to replace Unreleased (d5f4e3e)
- VersionUpdater#set_version for writing arbitrary version strings like Unreleased (33b3d76)
- Reissue.deferred_call sets VERSION to Unreleased and adds ## [Unreleased] changelog entry (76e3d61)
- Reissue.deferred_finalize resolves version from segment, explicit version, or git trailers at release time (1bdf36f)
- deferred_versioning flag for Reissue::Task to defer version bumping until finalize (aac3ade)
- Rake reissue task sets VERSION to Unreleased in deferred mode (aac3ade)
- Rake reissue:finalize task accepts version or segment argument in deferred mode (aac3ade)
- reissue_deferred_versioning attribute in Hoe plugin (e5a78d4)
- End-to-end integration tests for the deferred versioning workflow (77a313e)

### Changed

- set_version uses RELEASE_VERSION_MATCH paralleling RELEASE_DATE_MATCH pattern (efec0e5)
