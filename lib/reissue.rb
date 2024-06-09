# frozen_string_literal: true

require_relative "reissue/version"
require_relative "reissue/version_updater"
require_relative "reissue/changelog_updater"

# Reissue is a module that provides functionality for updating version numbers and changelogs.
module Reissue
  # Updates the version number and changelog.
  #
  # @param version_file [String] The path to the version file.
  # @param changelog_file [String] The path to the changelog file. Default: CHANGELOG.md
  # @param segment [String] The segment of the version number to update. Default: patch
  # @param date [String] The release date. Default: Unreleased
  # @param changes [Hash] The changes made in this release. Default: {}
  # @param version_limit [Integer] The number of versions to retain in the changes. Default: 2
  #
  # @return [String] The new version number.
  def self.call(
    version_file:,
    changelog_file: "CHANGELOG.md",
    segment: "patch",
    date: "Unreleased",
    changes: {},
    version_limit: 2
  )
    version_updater = VersionUpdater.new(version_file)
    new_version = version_updater.call(segment, version_file:)
    if changelog_file
      changelog_updater = ChangelogUpdater.new(changelog_file)
      changelog_updater.call(new_version, date:, changes:, changelog_file:, version_limit:)
    end
    new_version
  end

  # Finalizes the changelog for an unreleased version to set the release date.
  #
  # @param date [String] The release date.
  # @param changelog_file [String] The path to the changelog file.
  #
  # @return [Array] The version number and release date.
  def self.finalize(date = Date.today, changelog_file: "CHANGELOG.md")
    changelog_updater = ChangelogUpdater.new(changelog_file)
    changelog = changelog_updater.finalize(date:, changelog_file:)
    changelog["versions"].first.slice("version", "date").values
  end

  # Reformats the changelog file to ensure it is correctly formatted.
  #
  # @param file [String] The path to the changelog file.
  # @param version_limit [Integer] The number of versions to retain in the changelog. Default: 2
  def self.reformat(file, version_limit: 2)
    changelog_updater = ChangelogUpdater.new(file)
    changelog_updater.reformat(version_limit:)
  end
end
