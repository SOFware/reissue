# frozen_string_literal: true

require_relative "reissue/version"
require_relative "reissue/version_updater"
require_relative "reissue/changelog_updater"

# Reissue is a module that provides functionality for updating version numbers and changelogs.
module Reissue
  # Updates the version number and changelog.
  #
  # @param version_file [String] The path to the version file.
  # @param changelog_file [String] The path to the changelog file.
  # @param segment [String] The segment of the version number to update.
  # @param date [String] The release date.
  # @param changes [Hash] The changes made in this release.
  # @return [String] The new version number.
  def self.call(version_file:, changelog_file: "CHANGELOG.md", segment: "patch", date: "Unreleased", changes: {})
    version_updater = VersionUpdater.new(version_file)
    new_version = version_updater.call(segment, version_file:)
    if changelog_file
      changelog_updater = ChangelogUpdater.new(changelog_file)
      changelog_updater.call(new_version, date:, changes:, changelog_file:)
    end
    new_version
  end

  # Finalizes the changelog for an unreleased version to set the release date.
  #
  # @param date [String] The release date.
  # @param changelog_file [String] The path to the changelog file.
  def self.finalize(date = Date.today, changelog_file: "CHANGELOG.md")
    changelog_updater = ChangelogUpdater.new(changelog_file)
    changelog_updater.finalize(date:, changelog_file:)
  end
end
