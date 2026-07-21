# frozen_string_literal: true

module Reissue
  # Maintains a post-release runbook file listing steps to perform after
  # releasing a version. The file holds only the latest release.
  class Runbook
    ITEM_PATTERN = /^- (?:\[(?<checked>[ xX])\] )?(?<text>.+)$/

    def initialize(runbook_file)
      @runbook_file = runbook_file
    end

    attr_reader :runbook_file

    # Writes a header-only template for the given version.
    def generate(version: "Unreleased")
      File.write(runbook_file, template(heading(version)))
    end

    alias_method :clear, :generate

    # Returns the text of each checklist item, without checkbox markers.
    def items
      parsed_items.map { |item| item[:text] }
    end

    # Stamps the header with the release version and date, merging directly
    # edited items with trailer items (deduplicated by text).
    def finalize(version:, date:, trailer_items: [])
      merged = parsed_items
      texts = merged.map { |item| item[:text] }
      trailer_items.each do |text|
        merged << {text: text, checked: false} unless texts.include?(text)
      end
      File.write(runbook_file, template(heading(version, date), merged))
    end

    private

    def parsed_items
      return [] unless File.exist?(runbook_file)

      File.read(runbook_file).lines.filter_map do |line|
        match = line.rstrip.match(ITEM_PATTERN)
        next unless match
        {text: match[:text], checked: match[:checked]&.downcase == "x"}
      end
    end

    def heading(version, date = nil)
      date ? "## [#{version}] - #{date}" : "## [#{version}]"
    end

    def template(heading, items = [])
      header = <<~MARKDOWN
        # Runbook

        Steps to perform after releasing the version below.

        #{heading}
      MARKDOWN
      return header if items.empty?

      list = items.map { |item| "- [#{item[:checked] ? "x" : " "}] #{item[:text]}" }.join("\n")
      "#{header}\n#{list}\n"
    end
  end
end
