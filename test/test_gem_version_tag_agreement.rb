# frozen_string_literal: true

require "test_helper"
require "rake"
require "stringio"
require "tmpdir"

# Bundler loads the gemspec once, when bundler/gem_tasks is required, which is
# before reissue:bump rewrites the version file. `gem build` shells out and so
# re-reads the file, producing a gem at the bumped version, but the tag and the
# confirmation messages come from the copy bundler is still holding. Left alone
# they name the version before the bump.
class TestGemVersionTagAgreement < Minitest::Test
  include GitRepoHelpers

  def setup
    @rake = Rake::Application.new
    Rake.application = @rake
  end

  def teardown
    Rake.application.clear
  end

  def test_bundler_tags_the_version_the_bump_landed_on
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_project(version: "1.2.3")
        create_commit_with_trailer("New feature", "Added: A thing\n\nVersion: minor")

        create_rakefile
        load "Rakefile"

        capture_io { Rake::Task["reissue:bump"].invoke }

        assert_match(/VERSION = "1.3.0"/, File.read("version.rb"))

        helper = Bundler::GemHelper.instance
        assert_equal "1.3.0", helper.gemspec.version.to_s,
          "bundler must hold the bumped version, not the one it cached at load"
        # version_tag is protected; it is what release:source_control_push pushes
        assert_equal "v1.3.0", helper.send(:version_tag),
          "the release tag must name the version being published"
      end
    end
  end

  private

  def setup_project(version:)
    init_git_repo

    File.write("version.rb", "VERSION = \"#{version}\"\nRELEASE_DATE = \"Unreleased\"\n")
    File.write("CHANGELOG.md", <<~CHANGELOG)
      # Changelog

      ## [#{version}] - Unreleased

      ## [1.2.2] - 2026-01-01

      ### Added

      - Something earlier
    CHANGELOG

    # A gemspec that reads its version from the file reissue rewrites, the way a
    # real gem does.
    File.write("demo.gemspec", <<~RUBY)
      Gem::Specification.new do |spec|
        spec.name = "demo"
        spec.version = File.read(File.expand_path("version.rb", __dir__))[/VERSION = "([^"]+)"/, 1]
        spec.authors = ["Test"]
        spec.summary = "Demo"
        spec.files = []
      end
    RUBY

    commit_everything("Initial")
    tag_version(version)
  end

  def create_rakefile
    File.write("Rakefile", <<~RUBY)
      require "bundler/gem_tasks"
      require "reissue/gem"

      Reissue::Task.create :reissue do |task|
        task.version_file = "version.rb"
        task.fragment = :git
        task.commit_finalize = false
      end
    RUBY
  end
end
