# frozen_string_literal: true

require "test_helper"

class TestReissue < Minitest::Spec
  describe ".call" do
    it "updates the contents of the version file" do
      fixture = File.expand_path("fixtures/version.rb", __dir__)
      version_file = Tempfile.new
      version_file << File.read(fixture)
      version_file.close

      Reissue.call(version_file:, segment: "major", changelog_file: nil)

      assert_match(/1.0.0/, IO.read(version_file.path))
    end

    it "updates the contents of the changelog file" do
      fixture_version = File.expand_path("fixtures/version.rb", __dir__)
      version_file = Tempfile.new
      version_file << File.read(fixture_version)
      version_file.close

      fixture_changelog = File.expand_path("fixtures/changelog.md", __dir__)
      changelog_file = Tempfile.new
      changelog_file << File.read(fixture_changelog)
      changelog_file.close

      Reissue.call(
        version_file:,
        changelog_file:,
        segment: "major",
        date: "2021-01-01",
        changes: {"Added" => ["New feature"]}
      )
      contents = File.read(changelog_file)
      assert_match(/1.0.0/, contents)
      assert_match(/2021-01-01/, contents)
      assert_match(/New feature/, contents)
    end
  end

  describe ".finalize" do
    it "updates the contents of the changelog file" do
      fixture_changelog = File.expand_path("fixtures/changelog.md", __dir__)
      changelog_file = Tempfile.new
      changelog_file << File.read(fixture_changelog)
      changelog_file.close

      Reissue.finalize("2021-01-01", changelog_file: changelog_file.path)

      contents = File.read(changelog_file)

      assert_match(/\[0.1.2\] - 2021-01-01/, contents)
    end
  end

  describe ".reformat" do
    before do
      @file = File.expand_path("fixtures/changelog.md", __dir__)
      @tempfile = Tempfile.new
      @changelog_updater = Reissue::ChangelogUpdater.new(@file)
    end

    it "removes excess whitespace and inserts it where necessary" do
      @changelog_updater.reformat(@tempfile)
      result = File.read(@tempfile)
      assert_equal(<<~FIXED, result)
        # Change Log

        All notable changes to this project will be documented in this file.

        The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
        and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

        ## [0.1.2] - Unreleased

        ## [0.1.1] - 2017-06-20

        ### Added

        - New feature
        - More things

        ### Fixed

        - Bug fix

        ## [0.1.0] - 2017-06-19

        ### Added

        - Initial release
      FIXED
    end
  end
end
