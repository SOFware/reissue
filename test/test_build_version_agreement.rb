# frozen_string_literal: true

require "test_helper"
require "rake"
require "stringio"
require "tmpdir"

# The build task runs reissue:bump then reissue:finalize. Whatever version the
# bump lands on is the version the gem will be built as, so the changelog entry
# finalized alongside it has to carry that same version. When they disagree the
# release publishes a version with no changelog entry of its own.
class TestBuildVersionAgreement < Minitest::Test
  include GitRepoHelpers

  def setup
    @rake = Rake::Application.new
    Rake.application = @rake
  end

  def teardown
    Rake.application.clear
  end

  def test_finalized_changelog_entry_carries_the_bumped_version
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_project(version: "1.2.3")
        create_commit_with_trailer("New feature", "Added: A thing\n\nVersion: minor")

        create_rakefile
        load "Rakefile"

        capture_io do
          Rake::Task["reissue:bump"].invoke
          Rake::Task["reissue:finalize"].invoke
        end

        assert_match(/VERSION = "1.3.0"/, File.read("version.rb"))

        changelog = File.read("CHANGELOG.md")
        assert_match(/## \[1\.3\.0\] - \d{4}-\d{2}-\d{2}/, changelog,
          "the released version must have a dated changelog entry")
        refute_match(/## \[1\.2\.3\] - \d{4}-\d{2}-\d{2}/, changelog,
          "the previous version must not be dated as if it were this release")
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

    commit_everything("Initial")
    tag_version(version)
  end

  def create_rakefile
    File.write("Rakefile", <<~RUBY)
      require "reissue/rake"

      Reissue::Task.create :reissue do |task|
        task.version_file = "version.rb"
        task.fragment = :git
        task.commit_finalize = false
      end
    RUBY
  end
end
