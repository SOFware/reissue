# frozen_string_literal: true

require_relative "reissue/version"
require_relative "reissue/version_updater"
require_relative "reissue/changelog_updater"
require_relative "reissue/fragment_handler"

# Reissue is a module that provides functionality for updating version numbers and changelogs.
module Reissue
  DEFAULT_CHANGELOG_SECTIONS = %w[Added Changed Deprecated Removed Fixed Security].freeze

  def self.changelog_sections
    @changelog_sections ||= DEFAULT_CHANGELOG_SECTIONS.dup
  end

  def self.changelog_sections=(sections)
    @changelog_sections = Array(sections).map(&:capitalize).uniq
  end

  # Updates the version number and changelog.
  #
  # @param version_file [String] The path to the version file.
  # @param changelog_file [String] The path to the changelog file. Default: CHANGELOG.md
  # @param segment [String] The segment of the version number to update. Default: patch
  # @param date [String] The release date. Default: Unreleased
  # @param changes [Hash] The changes made in this release. Default: {}
  # @param version_limit [Integer] The number of versions to retain in the changes. Default: 2
  # @param fragment [String, nil] The fragment source configuration (directory path or nil to disable). Default: nil
  # @param fragment_directory [String] @deprecated Use fragment parameter instead
  #
  # @return [String] The new version number.
  def self.call(
    version_file:,
    changelog_file: "CHANGELOG.md",
    retain_changelogs: false,
    segment: "patch",
    date: "Unreleased",
    changes: {},
    version_limit: 2,
    version_redo_proc: nil,
    fragment: nil,
    fragment_directory: nil,
    tag_pattern: nil
  )
    # Handle deprecation
    if fragment_directory && !fragment
      warn "[DEPRECATION] `fragment_directory` parameter is deprecated. Please use `fragment` instead."
      fragment = fragment_directory
    end

    version_updater = VersionUpdater.new(version_file, version_redo_proc:)
    new_version = version_updater.call(segment, version_file:)
    if changelog_file
      changelog_updater = ChangelogUpdater.new(changelog_file)
      changelog_updater.call(new_version, date:, changes:, changelog_file:, version_limit:, retain_changelogs:, fragment:, tag_pattern:)
    end
    new_version
  end

  # Finalizes the changelog for an unreleased version to set the release date.
  #
  # @param date [String] The release date.
  # @param changelog_file [String] The path to the changelog file.
  # @param fragment [String, nil] The fragment source configuration (directory path or nil to disable). Default: nil
  # @param fragment_directory [String] @deprecated Use fragment parameter instead
  #
  # @return [Array] The version number and release date.
  def self.finalize(date = Date.today, changelog_file: "CHANGELOG.md", retain_changelogs: false, fragment: nil, fragment_directory: nil, tag_pattern: nil)
    # Handle deprecation
    if fragment_directory && !fragment
      warn "[DEPRECATION] `fragment_directory` parameter is deprecated. Please use `fragment` instead."
      fragment = fragment_directory
    end

    changelog_updater = ChangelogUpdater.new(changelog_file)

    # If fragments are present, we need to update the unreleased version with them first
    if fragment
      # Get the current changelog to find the unreleased version
      changelog = Parser.parse(File.read(changelog_file))
      unreleased_version = changelog["versions"].find { |v| v["date"] == "Unreleased" }

      if unreleased_version
        # Remove the unreleased version from the changelog to avoid duplication
        # when we call update (which does unshift)
        changelog["versions"].delete(unreleased_version)

        # Write the modified changelog (with unreleased version removed) back to file
        # This is necessary because update() re-parses from the file
        changelog_updater.instance_variable_set(:@changelog, changelog)
        changelog_updater.write(changelog_file, retain_changelogs: false)

        # Get fragment changes
        handler = FragmentHandler.for(fragment, tag_pattern:)
        fragment_changes = handler.read

        # Merge existing changes with fragment changes, deduplicating entries
        merged_changes = (unreleased_version["changes"] || {}).dup
        fragment_changes.each do |section, entries|
          merged_changes[section] ||= []
          # Only add entries that don't already exist
          entries.each do |entry|
            merged_changes[section] << entry unless merged_changes[section].include?(entry)
          end
        end

        # Update with merged data (this will unshift the version back into the array)
        changelog_updater.update(
          unreleased_version["version"],
          date: "Unreleased",
          changes: merged_changes,
          fragment: nil,  # Don't read fragments again since we already merged them
          version_limit: changelog["versions"].size + 1  # +1 because we removed one
        )
        changelog_updater.write(changelog_file, retain_changelogs: false)
      end
    end

    # Now finalize with the date
    changelog = changelog_updater.finalize(date:, changelog_file:, retain_changelogs:)

    changelog["versions"].first.slice("version", "date").values
  end

  # Reformats the changelog file to ensure it is correctly formatted.
  #
  # @param file [String] The path to the changelog file.
  # @param version_limit [Integer] The number of versions to retain in the changelog. Default: 2
  # @param retain_changelogs [Boolean, String, Proc] Whether to retain the changelog files for the previous versions.
  def self.reformat(file, version_limit: 2, retain_changelogs: false)
    changelog_updater = ChangelogUpdater.new(file)
    changelog_updater.reformat(version_limit:, retain_changelogs:)
  end

  INITIAL_CHANGES = {
    "Added" => ["Initial release"]
  }

  def self.generate_changelog(location, changes: {})
    template = <<~EOF
      # Changelog

      All notable changes to this project will be documented in this file.

      The format is based on [Keep a Changelog](http://keepachangelog.com/)
      and this project adheres to [Semantic Versioning](http://semver.org/).

      ## Unreleased

      ## [0.1.0]
    EOF

    File.write(location, template)
    changelog_updater = ChangelogUpdater.new(location)
    changelog_updater.call(
      "0.1.0",
      date: "Unreleased",
      changes: changes.empty? ? INITIAL_CHANGES : changes,
      changelog_file: location,
      version_limit: 1,
      retain_changelogs: false
    )
  end

  # Clears all fragment files in the specified source.
  #
  # @param fragment [String] The fragment source configuration.
  def self.clear_fragments(fragment)
    return unless fragment

    handler = FragmentHandler.for(fragment)
    handler.clear
  end
end
