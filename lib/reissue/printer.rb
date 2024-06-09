module Reissue
  class Printer
    def initialize(changelog)
      @changelog = changelog
      @title = @changelog["title"] || "Changelog"
      @preamble = @changelog["preamble"] || "All project changes are documented in this file."
      @versions = versions
    end

    def to_s = <<~MARKDOWN
      # #{@title}

      #{@preamble}

      #{@versions}
    MARKDOWN

    private

    def versions
      @changelog["versions"].map do |data|
        version = data["version"]
        date = data["date"]
        changes = data.fetch("changes") do
          {}
        end
        version_string = "## [#{version}] - #{date}"
        changes_string = changes.map do |section, changes|
          format_section(section, changes)
        end.join("\n\n")
        [version_string, changes_string].filter_map { |str| str unless str.empty? }.join("\n\n")
      end.then do |data|
        if data.empty?
          "## [0.0.0] - Unreleased"
        else
          data.join("\n\n")
        end
      end
    end

    def format_section(section, changes)
      <<~MARKDOWN.strip
        ### #{section}

        #{changes.map { |change| "- #{change}" }.join("\n")}
      MARKDOWN
    end
  end
end
