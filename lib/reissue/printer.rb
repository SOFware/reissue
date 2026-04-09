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
      @changelog["versions"].to_a.map do |data|
        version = data["version"]
        date = data["date"]
        changes = data.fetch("changes") do
          {}
        end
        version_string = if version == "Unreleased" && date.nil?
          "## [Unreleased]"
        else
          "## [#{version}] - #{date}"
        end
        changes_string = sorted_change_pairs(changes).map do |section, section_changes|
          format_section(section, section_changes)
        end.join("\n\n")
        [version_string, changes_string].reject { |str| str.empty? }.join("\n\n")
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

    # Keep section order aligned with rake / Reissue.changelog_sections (same rule as preview task).
    def sorted_change_pairs(changes)
      changes.sort_by do |section, _|
        idx = Reissue.changelog_sections.index(section) || 999
        [idx, section.to_s]
      end
    end
  end
end
