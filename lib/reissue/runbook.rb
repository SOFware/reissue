# frozen_string_literal: true

module Reissue
  # Maintains a post-release runbook file listing steps to perform after
  # releasing a version. The file holds only the latest release.
  class Runbook
    ITEM_PATTERN = /^- (?:\[(?<checked>[ xX])\] )?(?<text>.+)$/

    DEFAULT_TITLE = "Runbook"
    DEFAULT_PREAMBLE = "Steps to perform after releasing the version below."

    def initialize(runbook_file)
      @runbook_file = runbook_file
    end

    attr_reader :runbook_file

    # Writes a header-only template for the given version, preserving any
    # custom title and preamble already in the file.
    def generate(version: "Unreleased")
      title, preamble = parsed_header
      File.write(runbook_file, template(heading(version), title:, preamble:))
    end

    alias_method :clear, :generate

    # Returns the text of each checklist item, without checkbox markers.
    def items
      parsed_items.map { |item| item[:text] }
    end

    # Stamps the header with the release version and date, merging directly
    # edited items with trailer items (deduplicated by text). Preserves any
    # custom title and preamble already in the file.
    def finalize(version:, date:, trailer_items: [])
      title, preamble = parsed_header
      merged = parsed_items
      texts = merged.map { |item| item[:text] }
      trailer_items.each do |text|
        merged << {text: text, checked: false} unless texts.include?(text)
      end
      File.write(runbook_file, template(heading(version, date), merged, title:, preamble:))
    end

    private

    # Returns the [title, preamble] found before the first version heading,
    # falling back to the defaults when the file is missing or header-only.
    def parsed_header
      return [DEFAULT_TITLE, DEFAULT_PREAMBLE] unless File.exist?(runbook_file)

      header_chunk = File.read(runbook_file).split(/^## /, 2).first.to_s
      title_match = header_chunk.match(/^#\s+(?<title>.+)$/)
      title = title_match ? title_match[:title].strip : DEFAULT_TITLE
      preamble = (title_match ? header_chunk.sub(title_match[0], "") : header_chunk).strip
      preamble = DEFAULT_PREAMBLE if preamble.empty?
      [title, preamble]
    end

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

    def template(heading, items = [], title: DEFAULT_TITLE, preamble: DEFAULT_PREAMBLE)
      header = <<~MARKDOWN
        # #{title}

        #{preamble}

        #{heading}
      MARKDOWN
      return header if items.empty?

      list = items.map { |item| "- [#{item[:checked] ? "x" : " "}] #{item[:text]}" }.join("\n")
      "#{header}\n#{list}\n"
    end
  end
end
