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

    # The path to the changelog file.
    attr_accessor :changelog_file

    # Additional paths to add to the commit.
    attr_accessor :updated_paths

    # Whether to commit the changes. Default: true.
    attr_accessor :commit

    def initialize(name = :reissue)
      @name = name
      @description = "Prepare the code for work on a new version."
      @version_file = nil
      @updated_paths = []
      @changelog_file = "CHANGELOG.md"
      @commit = true
    end

    def define
      desc description
      task name, [:segment] do |task, args|
        segment = args[:segment] || "patch"
        Reissue.call(segment:, version_file:)
        if defined?(Bundler)
          Bundler.with_unbundled_env do
            system("bundle install")
          end
        end

        system("git add -u")
        if updated_paths.any?
          system("git add #{updated_paths.join(" ")}")
        end

        bump_message = "Bump version to #{Reissue::VERSION}"
        if commit
          system("git commit -m '#{bump_message}'")
        else
          system("echo '#{bump_message}'")
        end
      end

      desc "Reformat the changelog file to ensure it is correctly formatted."
      task "#{name}:reformat" do |task|
        Reissue.reformat(changelog_file)
      end

      desc "Finalize the changelog for an unreleased version to set the release date."
      task "#{name}:finalize", [:date] do |task, args|
        date = args[:date] || Time.now.strftime("%Y-%m-%d")
        Reissue.finalize(date, changelog_file:)
      end
    end
  end
end
