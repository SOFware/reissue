require "strscan"

module Reissue
  class Parser
    def self.parse(changelog)
      new(changelog).parse
    end

    def initialize(changelog)
      @changelog = changelog
      @versions = {}
      @parts = []
    end

    def parse
      scanner = StringScanner.new(@changelog)
      @parts << parse_title(scanner)
      @parts << parse_preamble(scanner)
      @parts << parse_versions(scanner)
      @parts.compact.reduce(&:merge)
    end

    VERSION_BREAK = "## "
    CHANGE_BREAK = "### "
    VERSION_MATCH = /^#{VERSION_BREAK}/
    VERSION_OR_CHANGE_MATCH = Regexp.union(CHANGE_BREAK, VERSION_BREAK)
    VERSION_OR_CHANGE_OR_NEWLINE_MATCH = Regexp.union(/\n/, CHANGE_BREAK, VERSION_BREAK)

    private

    def parse_title(scanner)
      scanner.scan(/# ([\w\s]+)$/)
      title = scanner[1].strip
      {"title" => title}
    end

    def parse_preamble(scanner)
      preamble = scanner.scan_until(VERSION_MATCH)
      preamble = preamble.gsub(VERSION_BREAK, "").strip
      scanner.unscan
      {"preamble" => preamble.strip}
    end

    def parse_versions(scanner)
      until scanner.eos?
        scanner.skip(/\s+/)
        next_line = scanner.scan_until(VERSION_OR_CHANGE_OR_NEWLINE_MATCH)
        break if next_line.nil? || next_line.strip.empty?
        unless next_line.match?(VERSION_OR_CHANGE_MATCH)
          parse_versions(scanner)
        end
        if next_line.match?(VERSION_MATCH)
          scanner.scan_until(/(.+)\n/)
          version, date = scanner[1].split(" - ")
          date ||= "Unreleased"
          version = version.gsub(VERSION_BREAK, "").strip.tr("[]", "")
          changes = parse_changes(scanner)
          @versions[version] = {"version" => version, "date" => date, "changes" => changes}
          parse_versions(scanner)
        end
      end
      {"versions" => @versions.values}
    end

    def parse_changes(scanner, changes: {})
      return changes if scanner.eos?
      scanner.skip(/\s+/)

      next_line = scanner.scan_until(/\n/)
      if next_line.nil? || next_line.strip.empty? || next_line.match?(VERSION_MATCH)
        scanner.unscan
        return changes
      end

      if next_line.match?(CHANGE_BREAK)
        change_type = next_line.gsub(CHANGE_BREAK, "").strip
        changes[change_type] = parse_change_list(scanner)
      end
      parse_changes(scanner, changes: changes)
    end

    def parse_change_list(scanner, collection: [])
      return collection if scanner.eos?
      scanner.skip(/\s+/)
      change = scanner.scan_until(/\n/)
      if change.nil? || change.strip.empty?
        return collection
      elsif change.match?(VERSION_OR_CHANGE_MATCH)
        scanner.unscan
        return collection
      else
        item = change.sub(/^\s?-\s?/, "").strip
        collection << item
        parse_change_list(scanner, collection:)
      end
      collection.reject(&:empty?).compact
    end
  end
end
