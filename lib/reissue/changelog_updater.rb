require_relative "parser"
require_relative "printer"

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
    # @param version_limit [Integer] The number of versions to keep (default: 2).
    def call(version, date: "Unreleased", changes: {}, changelog_file: @changelog_file, version_limit: 2)
      update(version, date:, changes:, version_limit:)
      write(changelog_file)
      changelog
    end

    def finalize(date: Date.today, changelog_file: @changelog_file)
      @changelog = Parser.parse(File.read(changelog_file))
      # find the highest version number and if it is unreleased, update the date
      version = changelog["versions"].max_by { |v| ::Gem::Version.new(v["version"]) }
      version_date = version["date"]
      if version_date.nil? || version_date == "Unreleased"
        changelog["versions"].find do |v|
          v["version"] == version["version"]
        end["date"] = date
      end
      write
      changelog
    end

    # Updates the changelog with a new version and its changes.
    #
    # @param version [String] The version number.
    # @param date [String] The release date (default: "Unreleased").
    # @param changes [Hash] The changes for the version (default: {}).
    # @param version_limit [Integer] The number of versions to keep (default: 2).
    # @return [Hash] The updated changelog.
    def update(version, date: "Unreleased", changes: {}, version_limit: 2)
      @changelog = Parser.parse(File.read(@changelog_file))

      changelog["versions"].unshift({"version" => version, "date" => date, "changes" => changes})
      changelog["versions"] = changelog["versions"].first(version_limit)
      changelog
    end

    # Reformats the changelog file to ensure it is correctly formatted.
    #
    # @param changelog_file [String] The path to the changelog file (default: @changelog_file).
    # @return [Hash] The parsed changelog.
    def reformat(result_file = @changelog_file, version_limit: 2)
      @changelog = Parser.parse(File.read(@changelog_file))
      changelog["versions"] = changelog["versions"].first(version_limit)
      write(result_file)
      changelog
    end

    # Returns the string representation of the changelog.
    #
    # @return [String] The Markdown string representation of the changelog.
    def to_s
      Printer.new(changelog).to_s
    end

    # Writes the changelog to the specified file.
    #
    # @param changelog_file [String] The path to the changelog file (default: @changelog_file).
    def write(changelog_file = @changelog_file)
      File.write(changelog_file, to_s)
    end
  end
end
