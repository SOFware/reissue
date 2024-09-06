# frozen_string_literal: true

require "rake/tasklib"
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

    # Additional paths to add to the commit.
    attr_writer :updated_paths

    def updated_paths
      Array(@updated_paths)
    end

    # Whether to commit the changes. Default: true.
    attr_accessor :commit

    # Whether to commit the finalize change to the changelog. Default: true.
    attr_accessor :commit_finalize

    # Whether to branch and push the changes. Default: :branch.
    # Requires commit_finialize to be true.
    #
    # Set this to false to disable pushing.
    # Set this to true to push to the current branch.
    # Set this to :branch to push to a new branch.
    attr_accessor :push_finalize

    def initialize(name = :reissue)
      @name = name
      @description = "Prepare the code for work on a new version."
      @version_file = nil
      @updated_paths = []
      @changelog_file = "CHANGELOG.md"
      @commit = true
      @commit_finalize = true
      @push_finalize = false
      @version_limit = 2
      @version_redo_proc = nil
    end

    def finalize_with_branch?
      push_finalize == :branch
    end

    def push_finalize?
      !!push_finalize
    end

    def define
      desc description
      task name, [:segment] do |task, args|
        segment = args[:segment] || "patch"
        new_version = Reissue.call(segment:, version_file:, version_limit:, version_redo_proc:)
        if defined?(Bundler)
          Bundler.with_unbundled_env do
            system("bundle install")
          end
        end

        system("git add -u")
        if updated_paths.any?
          system("git add #{updated_paths.join(" ")}")
        end

        bump_message = "Bump version to #{new_version}"
        if commit
          system("git commit -m '#{bump_message}'")
        else
          system("echo '#{bump_message}'")
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
        Reissue.reformat(changelog_file, version_limit:)
      end

      desc "Finalize the changelog for an unreleased version to set the release date."
      task "#{name}:finalize", [:date] do |task, args|
        date = args[:date] || Time.now.strftime("%Y-%m-%d")
        version, date = Reissue.finalize(date, changelog_file:)
        finalize_message = "Finalize the changelog for version #{version} on #{date}"
        if commit_finalize
          Rake::Task["#{name}:branch"].invoke("reissue/#{version}") if finalize_with_branch?
          system("git add -u")
          system("git commit -m '#{finalize_message}'")
          Rake::Task["#{name}:push"].invoke if push_finalize?
        else
          system("echo '#{finalize_message}'")
        end
      end

      desc "Create a new branch for the next version."
      task "#{name}:branch" => [:branch] do |task, args|
        raise "No branch name specified" unless args[:branch]
        system("git checkout -b #{args[:branch]}")
      end

      desc "Push the current branch to the remote repository."
      task "#{name}:push" do
        system("git push origin HEAD")
      end
    end
  end
end
