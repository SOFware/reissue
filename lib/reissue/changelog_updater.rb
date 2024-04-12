require "keepachangelog"

module Reissue
  # Updates the changelog file with new versions and changes.
  class ChangelogUpdater
    def initialize(changelog_file)
      @changelog_file = changelog_file
      @changelog = {}
    end

    attr_reader :changelog

    # Updates the changelog with a new version and its changes.
    #
    # @param version [String] The version number.
    # @param date [String] The release date (default: "Unreleased").
    # @param changes [Hash] The changes for the version (default: {}).
    # @param changelog_file [String] The path to the changelog file (default: @changelog_file).
    def call(version, date: "Unreleased", changes: {}, changelog_file: @changelog_file)
      update(version, date: date, changes: changes)
      write(changelog_file)
      changelog
    end

    def finalize(date: Date.today, changelog_file: @changelog_file)
      @changelog = Keepachangelog::MarkdownParser.parse(File.read(changelog_file))
      # find the highest version number and if it is unreleased, update the date
      version = changelog["versions"].keys.max
      version_date = changelog.dig("versions", version, "date")
      if version_date.nil? || version_date == "Unreleased"
        updated = changelog["versions"].delete(version)
        new_version = version.sub(/\s-.*/, "")
        changelog["versions"][new_version] = updated.merge("date" => date)
      end
      write(changelog_file)
      changelog
    end

    # Updates the changelog with a new version and its changes.
    #
    # @param version [String] The version number.
    # @param date [String] The release date (default: "Unreleased").
    # @param changes [Hash] The changes for the version (default: {}).
    def update(version, date: "Unreleased", changes: {})
      @changelog = Keepachangelog::MarkdownParser.parse(File.read(@changelog_file))

      changelog["versions"][version] = { "date" => date, "changes" => changes }
      changes.each do |section, change|
        changelog["versions"][version]["changes"][section] = change
      end
      changelog
    end

    # Returns the string representation of the changelog.
    #
    # @return [String] The Markdown string representation of the changelog.
    def to_s
      Keepachangelog::MarkdownPrinter.new(changelog["versions"]).to_s
    end

    # Writes the changelog to the specified file.
    #
    # @param changelog_file [String] The path to the changelog file (default: @changelog_file).
    def write(changelog_file = @changelog_file)
      File.write(changelog_file, to_s)
    end
  end
end
