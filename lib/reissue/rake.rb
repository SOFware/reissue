# frozen_string_literal: true

require "rake/tasklib"
require "open3"
require_relative "../reissue"

module Reissue
  class Task < Rake::TaskLib
    def self.create name = :reissue, &block
      task = new name
      task.instance_eval(&block) if block
      raise "No Reissue task.version_file specified" unless task.version_file
      task.define
      task
    end

    # The name of the main task and the namespace for the other tasks.
    attr_accessor :name

    # A description of the main task.
    attr_accessor :description

    # The path to the version file. Required.
    attr_accessor :version_file

    # The number of versions to retain in the changelog file. Defaults to 2.
    attr_accessor :version_limit

    # A proc that can be used to create the new version string.
    attr_accessor :version_redo_proc

    # The path to the changelog file.
    attr_accessor :changelog_file

    # Set to true to retain the changelog files for the previous versions.
    # Default: false.
    # Provide a callable to decide how to store the files.
    attr_accessor :retain_changelogs

    # The fragment configuration for changelog entries.
    # @return [String, nil] nil (disabled) or a directory path string for fragment files
    # @example Using directory-based fragments
    #   task.fragment = "changelog_fragments"
    # @note Default: nil (disabled)
    attr_accessor :fragment

    # @deprecated Use {#fragment} instead
    def fragment_directory=(value)
      warn "[DEPRECATION] `fragment_directory` is deprecated. Please use `fragment` instead."
      self.fragment = value
    end

    # @deprecated Use {#fragment} instead
    def fragment_directory
      warn "[DEPRECATION] `fragment_directory` is deprecated. Please use `fragment` instead."
      @fragment
    end

    # Whether to clear fragment files after processing.
    # Default: false.
    attr_accessor :clear_fragments

    # Additional paths to add to the commit.
    attr_writer :updated_paths

    def updated_paths
      Array(@updated_paths)
    end

    # Whether to commit the changes. Default: true.
    attr_accessor :commit

    # Whether to commit the finalize change to the changelog. Default: true.
    attr_accessor :commit_finalize

    # Whether to commit the clear fragments change.
    # Returns false for :git fragments since there are no files to commit.
    attr_writer :commit_clear_fragments

    def commit_clear_fragments
      return false if fragment == :git
      @commit_clear_fragments
    end

    # Whether to branch and push the changes. Default: :branch.
    # Requires commit_finialize to be true.
    #
    # Set this to false to disable pushing.
    # Set this to true to push to the current branch.
    # Set this to :branch to push to a new branch.
    attr_accessor :push_finalize

    # Whether to push the changes when a new version is created. Default: :branch.
    # Requires commit to be true.
    #
    # Set this to false to disable pushing.
    # Set this to true to push to the current branch.
    # Set this to :branch to push to a new branch.
    attr_accessor :push_reissue

    # Optional regex pattern for matching version tags.
    # Must include a capture group for the version number.
    # Examples:
    #   - /^v(\d+\.\d+\.\d+.*)$/ matches "v1.2.3" (default)
    #   - /^myapp-v(\d+\.\d+\.\d+.*)$/ matches "myapp-v1.2.3"
    #   - /^qualified-v(\d+\.\d+\.\d+.*)$/ matches "qualified-v0.3.5"
    # Default: nil (uses default pattern matching "v1.2.3")
    attr_accessor :tag_pattern

    def initialize(name = :reissue, formatter: Reissue, tasker: Rake::Task)
      @name = name
      @formatter = formatter
      @tasker = tasker
      @description = "Prepare the code for work on a new version."
      @version_file = nil
      @updated_paths = []
      @changelog_file = "CHANGELOG.md"
      @retain_changelogs = false
      @fragment = nil
      @clear_fragments = false
      @commit = true
      @commit_finalize = true
      @commit_clear_fragments = true
      @push_finalize = false
      @version_limit = 2
      @version_redo_proc = nil
      @push_reissue = :branch
      @tag_pattern = nil
    end

    attr_reader :formatter, :tasker
    private :formatter, :tasker

    # Run a shell command and raise an error with details if it fails
    def run_command(command, error_message)
      stdout, stderr, status = Open3.capture3(command)
      unless status.success?
        error_details = [error_message]
        error_details << "Command: #{command}"
        error_details << "Exit status: #{status.exitstatus}"
        error_details << "STDOUT: #{stdout.strip}" unless stdout.strip.empty?
        error_details << "STDERR: #{stderr.strip}" unless stderr.strip.empty?
        raise error_details.join("\n")
      end
      stdout
    end

    def finalize_with_branch?
      push_finalize == :branch
    end

    def push_finalize?
      !!push_finalize
    end

    def reissue_version_with_branch?
      push_reissue == :branch
    end

    def push_reissue?
      !!push_reissue
    end

    def bundle
      if defined?(Bundler) && File.exist?("Gemfile")
        Bundler.with_unbundled_env do
          system("bundle install")
        end
      end
    end

    def define
      desc description
      task name, [:segment] do |task, args|
        segment = args[:segment] || "patch"
        new_version = formatter.call(
          segment:,
          version_file:,
          changelog_file:,
          version_limit:,
          version_redo_proc:,
          fragment: fragment
        )
        bundle

        tasker["#{name}:clear_fragments"].invoke

        run_command("git add -u", "Failed to stage updated files")
        if updated_paths&.any?
          run_command("git add #{updated_paths.join(" ")}", "Failed to stage additional paths: #{updated_paths.join(", ")}")
        end

        bump_message = "Bump version to #{new_version}"
        if commit
          if reissue_version_with_branch?
            tasker["#{name}:branch"].invoke("reissue/#{new_version}")
          end
          run_command("git commit -m '#{bump_message}'", "Failed to commit version bump")
          tasker["#{name}:push"].invoke if push_reissue?
        else
          puts bump_message
        end

        new_version
      end

      desc "Reformat the changelog file to ensure it is correctly formatted."
      task "#{name}:reformat", [:version_limit] do |task, args|
        version_limit = if args[:version_limit].nil?
          self.version_limit
        else
          args[:version_limit].to_i
        end
        unless File.exist?(changelog_file)
          formatter.generate_changelog(changelog_file)
        end
        formatter.reformat(changelog_file, version_limit:, retain_changelogs:)
      end

      desc "Finalize the changelog for an unreleased version to set the release date."
      task "#{name}:finalize", [:date] do |task, args|
        date = args[:date] || Time.now.strftime("%Y-%m-%d")
        version, date = formatter.finalize(
          date,
          changelog_file:,
          retain_changelogs:,
          fragment: fragment
        )
        finalize_message = "Finalize the changelog for version #{version} on #{date}"
        if commit_finalize
          if finalize_with_branch?
            # Use "finalize/" prefix for the version being released
            tasker["#{name}:branch"].invoke("finalize/#{version}")
          end
          run_command("git add -u", "Failed to stage finalized changelog")
          run_command("git commit -m '#{finalize_message}'", "Failed to commit finalized changelog")
          tasker["#{name}:push"].invoke if push_finalize?
        else
          puts finalize_message
        end
      end

      desc <<~MSG
        Create a new branch for the next version.

        If the branch already exists it will be deleted and a new one will be created along with a new tag.
      MSG

      task "#{name}:branch", [:branch_name] do |task, args|
        raise "No branch name specified" unless args[:branch_name]
        branch_name = args[:branch_name]
        # Force create branch by deleting if exists, then creating fresh
        if system("git show-ref --verify --quiet refs/heads/#{branch_name}")
          # Extract version from branch name (e.g., "reissue/0.4.1" -> "0.4.1")
          version = branch_name.sub(/^reissue\//, "")
          # Delete matching tag if it exists
          system("git tag -d v#{version} 2>/dev/null || true")
          # Delete the local branch
          run_command("git branch -D #{branch_name}", "Failed to delete existing branch #{branch_name}")
          # Delete the remote tracking ref to prevent --force-with-lease from comparing against stale data
          system("git branch -d -r origin/#{branch_name} 2>/dev/null")
        end
        run_command("git checkout -b #{branch_name}", "Failed to create and checkout branch #{branch_name}")
      end

      desc "Push the current branch to the remote repository."
      task "#{name}:push" do
        run_command("git push --force-with-lease origin HEAD", "Failed to push to remote repository")
      end

      desc "Preview changelog entries that will be added from fragments or git trailers"
      task "#{name}:preview" do
        if fragment
          require_relative "fragment_handler"
          handler = Reissue::FragmentHandler.for(fragment, tag_pattern: tag_pattern)

          # Show comparison tag for git trailers
          if fragment == :git && handler.respond_to?(:last_tag)
            last_tag = handler.last_tag
            if last_tag
              puts "Comparing against: #{last_tag}"
              puts "  (Run 'git fetch --tags' if this seems out of date)\n\n"
            else
              puts "No version tags found (comparing against all commits)\n\n"
            end
          end

          entries = handler.read

          if entries.empty?
            puts "No changelog entries found."
            if fragment == :git
              puts "  (No git trailers found since last version tag)"
            else
              puts "  (No fragment files found in '#{fragment}')"
            end
          else
            puts "Changelog entries that will be added:\n\n"
            # Sort sections in Keep a Changelog order
            section_order = %w[Added Changed Deprecated Removed Fixed Security]
            sorted_sections = entries.keys.sort_by { |k| section_order.index(k) || 999 }

            sorted_sections.each do |section|
              items = entries[section]
              puts "### #{section}\n"
              items.each { |item| puts "- #{item}" }
              puts
            end

            puts "Total: #{entries.values.flatten.count} entries across #{entries.keys.count} sections"
          end
        else
          puts "Fragment handling is not configured."
          puts "Set task.fragment to a directory path or :git to enable changelog fragments."
        end
      end

      desc "Clear fragments"
      task "#{name}:clear_fragments" do
        # Clear fragments after release if configured
        # Only run for directory-based fragments, not :git
        if fragment && clear_fragments && fragment.is_a?(String)
          formatter.clear_fragments(fragment)
          clear_message = "Clear changelog fragments"
          if commit_clear_fragments
            run_command("git add #{fragment}", "Failed to stage cleared fragments")
            run_command("git commit -m '#{clear_message}'", "Failed to commit cleared fragments")
          else
            puts clear_message
          end
        end
      end

      desc "Bump version based on git trailers"
      task "#{name}:bump" do
        # Only check for version trailers when using git fragments
        next unless fragment == :git

        require_relative "fragment_handler"
        require_relative "version_updater"

        handler = Reissue::FragmentHandler.for(:git, tag_pattern: tag_pattern)

        # Get current version from version file
        version_content = File.read(version_file)
        current_version = ::Gem::Version.new(version_content.match(Reissue::VersionUpdater::VERSION_MATCH)[0])

        # Get version from last git tag
        tag_version = handler.last_tag_version

        # Only bump if current version matches tag version (hasn't been bumped yet)
        if tag_version && current_version == tag_version
          bump = handler.read_version_bump

          if bump
            updater = Reissue::VersionUpdater.new(version_file, version_redo_proc: version_redo_proc)
            updater.call(bump)
            puts "Version bumped (#{bump}) to #{updater.instance_variable_get(:@new_version)}"
          end
        elsif tag_version && current_version != tag_version
          puts "Version already bumped (#{tag_version} → #{current_version}), skipping"
        else
          # No tag exists, check for version trailers anyway
          bump = handler.read_version_bump

          if bump
            updater = Reissue::VersionUpdater.new(version_file, version_redo_proc: version_redo_proc)
            updater.call(bump)
            puts "Version bumped (#{bump}) to #{updater.instance_variable_get(:@new_version)}"
          end
        end
      end
    end
  end
end
