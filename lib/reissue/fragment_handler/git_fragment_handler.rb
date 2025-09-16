# frozen_string_literal: true

module Reissue
  class FragmentHandler
    # Handles reading changelog entries from git commit trailers
    class GitFragmentHandler < FragmentHandler
      # Regex to match changelog section trailers in commit messages
      TRAILER_REGEX = /^(Added|Changed|Deprecated|Removed|Fixed|Security):\s*(.+)$/i

      # Valid changelog sections that can be used as trailers
      VALID_SECTIONS = %w[Added Changed Deprecated Removed Fixed Security].freeze

      # Read changelog entries from git commit trailers
      #
      # @return [Hash] A hash of changelog entries organized by section
      def read
        return {} unless git_available? && in_git_repo?

        commits = commits_since_last_tag
        parse_trailers_from_commits(commits)
      end

      # Clear operation is a no-op for git trailers
      #
      # @return [nil]
      def clear
        nil
      end

      private

      def git_available?
        system("git --version", out: File::NULL, err: File::NULL)
      end

      def in_git_repo?
        system("git rev-parse --git-dir", out: File::NULL, err: File::NULL)
      end

      def commits_since_last_tag
        last_tag = find_last_tag

        commit_range = if last_tag
          # Get commits since the last tag
          "#{last_tag}..HEAD"
        else
          # No tags found, get all commits
          "HEAD"
        end

        # Get commit messages with trailers, in reverse order (oldest first)
        output = `git log #{commit_range} --reverse --format=%B 2>/dev/null`
        return [] if output.empty?

        # Split by double newline to separate commits
        output.split(/\n\n+/)
      end

      def find_last_tag
        # Try to find the most recent tag
        tag = `git describe --tags --abbrev=0 2>/dev/null`.strip
        tag.empty? ? nil : tag
      end

      def parse_trailers_from_commits(commits)
        result = {}

        commits.each do |commit|
          # Split commit into lines and look for trailers
          commit.lines.each do |line|
            line = line.strip
            next if line.empty?

            if (match = line.match(TRAILER_REGEX))
              section_name = normalize_section_name(match[1])
              trailer_value = match[2].strip

              result[section_name] ||= []
              result[section_name] << trailer_value
            end
          end
        end

        result
      end

      def normalize_section_name(name)
        # Normalize to proper case (e.g., "FIXED" -> "Fixed", "added" -> "Added")
        name.capitalize
      end
    end
  end
end
