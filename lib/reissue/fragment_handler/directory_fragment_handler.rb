# frozen_string_literal: true

require "pathname"

module Reissue
  # Handler for reading fragments from a directory
  class DirectoryFragmentHandler < FragmentHandler
    DEFAULT_VALID_SECTIONS = %w[added changed deprecated removed fixed security].freeze

    attr_reader :directory, :valid_sections

    # Initialize the handler with a directory path
    #
    # @param directory [String] The path to the fragments directory
    # @param valid_sections [Array<String>, nil] List of valid section names, or nil to allow all
    def initialize(directory, valid_sections: DEFAULT_VALID_SECTIONS)
      @directory = directory
      @fragment_directory = Pathname.new(directory)
      @valid_sections = valid_sections
    end

    # Read fragments from the directory
    #
    # @return [Hash] A hash of changelog entries organized by category
    def read
      return {} unless @fragment_directory.exist?

      fragments = {}

      @fragment_directory.glob("*.*.md").each do |fragment_file|
        filename = fragment_file.basename.to_s
        parts = filename.split(".")

        next unless parts.length == 3

        section = parts[1].downcase
        next unless valid_section?(section)

        content = fragment_file.read.strip
        next if content.empty?

        # Capitalize section name for changelog format
        section_key = section.capitalize
        fragments[section_key] ||= []
        fragments[section_key] << content
      end

      fragments
    end

    # Clear all fragment files from the directory
    #
    # @return [nil]
    def clear
      return unless @fragment_directory.exist?

      @fragment_directory.glob("*.*.md").each(&:delete)
    end

    private

    def valid_section?(section)
      return true if @valid_sections.nil?
      return false unless @valid_sections.is_a?(Array)

      @valid_sections.map(&:downcase).include?(section.downcase)
    end
  end
end
