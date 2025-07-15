require "pathname"

module Reissue
  class FragmentReader
    DEFAULT_VALID_SECTIONS = %w[added changed deprecated removed fixed security].freeze

    def initialize(fragment_directory = "changelog.d", valid_sections: DEFAULT_VALID_SECTIONS)
      @fragment_directory = Pathname.new(fragment_directory)
      @valid_sections = valid_sections
    end

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
