# frozen_string_literal: true

module Reissue
  class FragmentHandler
    # Handles reading changelog entries from git commit trailers
    class GitFragmentHandler < FragmentHandler
      # Valid changelog sections that can be used as trailers
      VALID_SECTIONS = %w[Added Changed Deprecated Removed Fixed Security].freeze

      # Regex to match changelog section trailers in commit messages
      TRAILER_REGEX = /^(#{VALID_SECTIONS.join("|")}):\s*(.+)$/i

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

      # Get the last version tag used for comparison
      #
      # @return [String, nil] The most recent version tag or nil if no tags found
      def last_tag
        return nil unless git_available? && in_git_repo?
        find_last_tag
      end

      # Read version bump from git commit trailers
      #
      # @return [Symbol, nil] One of :major, :minor, :patch, or nil if none found
      def read_version_bump
        return nil unless git_available? && in_git_repo?

        commits = commits_since_last_tag
        parse_version_bump_from_commits(commits)
      end

      # Get the version from the last git tag
      #
      # @return [Gem::Version, nil] The version from the last tag, or nil if no tags exist
      def last_tag_version
        tag = last_tag
        return nil unless tag

        # Extract version number from tag (e.g., "v1.2.3" -> "1.2.3")
        version_string = tag.sub(/^v/, "")
        ::Gem::Version.new(version_string)
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

        # Get commit hash and message using format specifiers
        # %h = short hash, %x00 = null byte separator, %B = commit body
        output = `git log #{commit_range} --reverse --format='%h%x00%B%x00' 2>/dev/null`
        return [] if output.empty?

        # Split by null bytes and group into pairs of (hash, message)
        parts = output.split("\x00")
        commits = []

        # Process pairs: hash, message, (empty from double null), repeat
        i = 0
        while i < parts.length - 1
          sha = parts[i].strip
          message = parts[i + 1] || ""

          if !sha.empty?
            commits << {sha: sha, message: message}
          end

          i += 2
        end

        commits
      end

      # Find the most recent semantic version tag (v*.*.*) by tag creation date across all branches
      # This ensures we exclude commits that are already in ANY tagged release, not just the current branch
      # Supports both numeric (v1.2.3) and alphanumeric (v2025.10.C) version tags
      #
      # @return [String, nil] The most recent version tag or nil if no tags found
      def find_last_tag
        tag = `git for-each-ref --sort=-creatordate --format='%(refname:short)' 'refs/tags/v[0-9]*.[0-9]*.[a-zA-Z0-9]*' --count=1 2>/dev/null`.strip
        tag.empty? ? nil : tag
      end

      def parse_trailers_from_commits(commits)
        result = {}

        commits.each do |commit|
          sha = commit[:sha]
          message = commit[:message]
          lines = message.lines

          i = 0
          while i < lines.length
            line = lines[i].rstrip
            i += 1
            next if line.strip.empty?

            if (match = line.match(TRAILER_REGEX))
              section_name = normalize_section_name(match[1])
              trailer_value = match[2].strip

              # Collect continuation lines (non-empty lines that don't start a new trailer)
              while i < lines.length
                next_line = lines[i].rstrip
                # Stop at empty line or any key:value pattern (trailer-like line)
                break if next_line.strip.empty?
                break if next_line.match(/^\w+:\s*.+$/)

                trailer_value += " #{next_line.strip}"
                i += 1
              end

              result[section_name] ||= []
              # Append the short SHA in parentheses
              result[section_name] << "#{trailer_value} (#{sha})"
            end
          end
        end

        result
      end

      def normalize_section_name(name)
        # Normalize to proper case (e.g., "FIXED" -> "Fixed", "added" -> "Added")
        name.capitalize
      end

      def parse_version_bump_from_commits(commits)
        # Precedence order (major > minor > patch)
        precedence = {major: 3, minor: 2, patch: 1}

        # Regex to match version trailers
        version_regex = /^version:\s*(major|minor|patch)\s*$/i

        highest_bump = nil
        highest_precedence = 0

        commits.each do |commit|
          message = commit[:message]

          # Split commit message into lines and look for version trailers
          message.lines.each do |line|
            line = line.strip
            next if line.empty?

            if (match = line.match(version_regex))
              bump_value = match[1].downcase.to_sym

              # Check if this bump has higher precedence
              if precedence[bump_value] && precedence[bump_value] > highest_precedence
                highest_bump = bump_value
                highest_precedence = precedence[bump_value]
              end
            end
          end
        end

        highest_bump
      end
    end
  end
end
