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

    it "retains changelog history when specified" do
      fixture_version = File.expand_path("fixtures/version.rb", __dir__)
      version_file = Tempfile.new
      version_file << File.read(fixture_version)
      version_file.close

      fixture_changelog = File.expand_path("fixtures/changelog.md", __dir__)
      changelog_file = Tempfile.new
      changelog_file << File.read(fixture_changelog)
      changelog_file.close

      Dir.mktmpdir do |tempdir|
        Reissue.call(
          version_file:,
          changelog_file: changelog_file.path,
          retain_changelogs: tempdir,
          segment: "major",
          changes: {"Added" => ["New feature"]}
        )

        retained_file = File.join(tempdir, "1.0.0.md")
        assert File.exist?(retained_file)
        contents = File.read(retained_file)
        assert_match(/\[1.0.0\]/, contents)
        assert_match(/New feature/, contents)
      end
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

    it "returns the version number and release date" do
      fixture_changelog = File.expand_path("fixtures/changelog.md", __dir__)
      changelog_file = Tempfile.new
      changelog_file << File.read(fixture_changelog)
      changelog_file.close

      version, date = Reissue.finalize("2021-01-01", changelog_file: changelog_file.path)

      assert_equal("0.1.2", version)
      assert_equal("2021-01-01", date)
    end

    it "retains changelog history when specified" do
      fixture_changelog = File.expand_path("fixtures/changelog.md", __dir__)
      tempdir = Dir.mktmpdir
      changelog_file = Tempfile.new
      changelog_file << File.read(fixture_changelog)
      changelog_file.close
      Reissue.finalize("2021-01-01", changelog_file: changelog_file.path, retain_changelogs: tempdir)
      assert File.exist?(File.join(tempdir, "0.1.2.md"))
    end
  end

  describe ".reformat" do
    it "removes excess whitespace and inserts it where necessary" do
      fixture_changelog = File.expand_path("fixtures/changelog.md", __dir__)
      changelog_file = Tempfile.new
      changelog_file << File.read(fixture_changelog)
      changelog_file.close

      Reissue.reformat(changelog_file.path, version_limit: 3)
      result = File.read(changelog_file)
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
          with extra lines

        ### Fixed

        - Bug fix

        ## [0.1.0] - 2017-06-19

        ### Added

        - Initial release
      FIXED
    end
  end

  describe ".generate_changelog" do
    it "creates a new changelog file with initial content" do
      changelog_file = Tempfile.new
      version_file = Tempfile.new
      version_file.write("module MyGem\n  VERSION = '0.1.0'\nend")
      version_file.close

      Reissue.generate_changelog(changelog_file.path)

      contents = File.read(changelog_file)
      assert_match(/Changelog/, contents)
      assert_match(/Keep a Changelog/, contents)
      assert_match(/Semantic Versioning/, contents)
      assert_match(/Unreleased/, contents)
      assert_match(/\[0.1.0\]/, contents)
      assert_match(/Initial release/, contents)
    end

    it "accepts custom changes" do
      changelog_file = Tempfile.new
      version_file = Tempfile.new
      version_file.write("module MyGem\n  VERSION = '0.1.0'\nend")
      version_file.close

      custom_changes = {
        "Added" => ["Custom feature"],
        "Fixed" => ["Bug fix"]
      }

      Reissue.generate_changelog(changelog_file.path, changes: custom_changes)

      contents = File.read(changelog_file)
      assert_match(/\[0.1.0\]/, contents)
      assert_match(/### Added/, contents)
      assert_match(/Custom feature/, contents)
      assert_match(/### Fixed/, contents)
      assert_match(/Bug fix/, contents)
    end
  end

  describe ".clear_fragments" do
    it "clears all fragment files in the directory" do
      Dir.mktmpdir do |tempdir|
        fragment_dir = File.join(tempdir, "fragments")
        Dir.mkdir(fragment_dir)

        # Create some fragment files
        File.write(File.join(fragment_dir, "123.added.md"), "Feature 1")
        File.write(File.join(fragment_dir, "124.fixed.md"), "Bug fix")
        File.write(File.join(fragment_dir, "125.changed.md"), "Updated something")

        # Verify files exist
        assert File.exist?(File.join(fragment_dir, "123.added.md"))
        assert File.exist?(File.join(fragment_dir, "124.fixed.md"))
        assert File.exist?(File.join(fragment_dir, "125.changed.md"))

        # Clear fragments
        Reissue.clear_fragments(fragment_dir)

        # Verify files are removed
        refute File.exist?(File.join(fragment_dir, "123.added.md"))
        refute File.exist?(File.join(fragment_dir, "124.fixed.md"))
        refute File.exist?(File.join(fragment_dir, "125.changed.md"))
      end
    end

    it "handles non-existent directory gracefully" do
      # Should not raise an error
      Reissue.clear_fragments("/non/existent/directory")
    end

    it "handles nil directory gracefully" do
      # Should not raise an error
      Reissue.clear_fragments(nil)
    end
  end
end
