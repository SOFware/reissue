# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "rake"
require "reissue/rake"

module Reissue
  class RakeInitializeTest < Minitest::Test
    def setup
      @original_dir = Dir.pwd
    end

    def teardown
      Dir.chdir(@original_dir)
      # Re-enable the task for the next test
      Rake::Task["reissue:initialize"].reenable
    end

    def test_creates_changelog_when_missing
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          refute File.exist?("CHANGELOG.md")

          output = capture_io { Rake::Task["reissue:initialize"].invoke }.first

          assert File.exist?("CHANGELOG.md"), "CHANGELOG.md should be created"
          assert_match(/Created CHANGELOG\.md/, output)
        end
      end
    end

    def test_does_not_overwrite_existing_changelog
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          existing_content = "# My Existing Changelog\n\nCustom content here."
          File.write("CHANGELOG.md", existing_content)

          output = capture_io { Rake::Task["reissue:initialize"].invoke }.first

          assert_equal existing_content, File.read("CHANGELOG.md")
          assert_match(/CHANGELOG\.md already exists/, output)
        end
      end
    end

    def test_outputs_rakefile_configuration
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          output = capture_io { Rake::Task["reissue:initialize"].invoke }.first

          assert_match(/require "reissue\/rake"/, output)
          assert_match(/Reissue::Task\.create :reissue/, output)
          assert_match(/task\.version_file/, output)
        end
      end
    end

    def test_outputs_optional_configuration
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          output = capture_io { Rake::Task["reissue:initialize"].invoke }.first

          assert_match(/Optional configuration/, output)
          assert_match(/task\.changelog_file/, output)
          assert_match(/task\.fragment/, output)
          assert_match(/task\.commit/, output)
        end
      end
    end

    def test_outputs_gem_usage_instructions
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          output = capture_io { Rake::Task["reissue:initialize"].invoke }.first

          assert_match(/require "reissue\/gem"/, output)
          assert_match(/automatic integration with bundler/, output)
        end
      end
    end

    def test_created_changelog_has_proper_format
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          capture_io { Rake::Task["reissue:initialize"].invoke }

          content = File.read("CHANGELOG.md")

          assert_match(/# Changelog/, content)
          assert_match(/Keep a Changelog/, content)
          assert_match(/Semantic Versioning/, content)
          assert_match(/## \[0\.1\.0\]/, content)
        end
      end
    end
  end
end
