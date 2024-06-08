require "kramdown"

module Reissue
  class Printer
    def initialize(changelog)
      @changelog = changelog
      @title = @changelog["title"]
      @preamble = @changelog["preamble"]
      @versions = versions
    end

    def template = <<~MARKDOWN
      # #{@title}

      #{@preamble}

      #{@versions}
    MARKDOWN

    def to_s
      Kramdown::Document.new(template).to_kramdown
    end

    private

    def versions
      @changelog["versions"].map do |data|
        version = data["version"]
        date = data["date"]
        changes = data.fetch("changes") do
          {}
        end
        <<~MARKDOWN
          ## #{version} - #{date}
          #{changes.map { |section, changes| format_section(section, changes) }.join("\n")}
        MARKDOWN
      end.join("\n")
    end

    def format_section(section, changes)
      <<~MARKDOWN
        ### #{section}
        #{changes.map { |change| "- #{change}" }.join("\n")}
      MARKDOWN
    end
  end
end