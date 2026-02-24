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

    it "forwards tag_pattern to the git fragment handler" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          setup_git_repo_with_custom_tag("v2026.02.A")
          create_commit_with_trailer(
            "Post-release work",
            "Added: New feature after release"
          )

          version_file = "lib/test/version.rb"
          FileUtils.mkdir_p("lib/test")
          File.write(version_file, <<~RUBY)
            module Test
              VERSION = "2026.02.A"
            end
          RUBY

          changelog_file = "CHANGELOG.md"
          File.write(changelog_file, <<~MD)
            # Changelog

            ## [2026.02.A] - 2026-02-24

            ### Added

            - Initial release
          MD

          tag_pattern =
            /^v(\d+\.\d+\.([A-Z]+|\d+))$/
          Reissue.call(
            version_file:,
            changelog_file:,
            segment: "patch",
            version_limit: 1,
            fragment: :git,
            tag_pattern:
          )

          contents = File.read(changelog_file)
          assert_match(
            /New feature after release/, contents,
            "Should include post-tag trailer"
          )
          refute_match(
            /Initial release/, contents,
            "Should NOT include pre-tag entries"
          )
        end
      end
    end
    it "resets RELEASE_DATE to Unreleased when bumping version" do
      version_file = Tempfile.new
      version_file << "module MyGem\n  VERSION = \"0.1.0\"\n  RELEASE_DATE = \"2026-02-24\"\nend\n"
      version_file.close

      Reissue.call(version_file:, segment: "patch", changelog_file: nil)

      contents = File.read(version_file)
      assert_match(/RELEASE_DATE = "Unreleased"/, contents)
    end

    it "does not fail when RELEASE_DATE is absent during bump" do
      fixture = File.expand_path("fixtures/version.rb", __dir__)
      version_file = Tempfile.new
      version_file << File.read(fixture)
      version_file.close

      Reissue.call(version_file:, segment: "major", changelog_file: nil)

      contents = File.read(version_file)
      refute_match(/RELEASE_DATE/, contents)
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

    it "merges git trailer changes with existing unreleased changes without duplication" do
      # Create a changelog with an unreleased version that has existing changes
      # and an older released version
      changelog_file = Tempfile.new
      changelog_file << <<~CHANGELOG
        # Changelog

        All notable changes to this project will be documented in this file.

        The format is based on [Keep a Changelog](http://keepachangelog.com/)
        and this project adheres to [Semantic Versioning](http://semver.org/).

        ## [0.4.5] - Unreleased

        ### Added

        - Existing feature from changelog

        ## [0.4.4] - 2025-10-17

        ### Added

        - Old feature
      CHANGELOG
      changelog_file.close

      # Create a temporary git repo to simulate git trailers
      Dir.mktmpdir do |tempdir|
        Dir.chdir(tempdir) do
          system("git init -q")
          system("git config user.email 'test@example.com'")
          system("git config user.name 'Test User'")

          # Create an initial commit with a version tag
          File.write("README.md", "Initial")
          system("git add .")
          system("git commit -q -m 'Initial commit'")
          system("git tag v0.4.4")

          # Create commits with git trailers
          File.write("feature1.txt", "Feature 1")
          system("git add .")
          system("git commit -q -m 'Add feature 1' -m 'Added: Feature from git trailer'")

          File.write("feature2.txt", "Feature 2")
          system("git add .")
          system("git commit -q -m 'Fix bug' -m 'Fixed: Bug fix from git trailer'")

          # Copy the changelog into the repo
          FileUtils.cp(changelog_file.path, "CHANGELOG.md")

          # Finalize with git trailers
          Reissue.finalize("2025-11-20", changelog_file: "CHANGELOG.md", fragment: :git)

          contents = File.read("CHANGELOG.md")

          # Should have exactly one 0.4.5 entry with the release date
          assert_equal 1, contents.scan(/## \[0.4.5\]/).length,
            "Should have exactly one 0.4.5 version entry, but found: #{contents.scan(/## \[0.4.5\].*/).inspect}"

          # Should not have an unreleased 0.4.5
          refute_match(/\[0.4.5\] - Unreleased/, contents,
            "Should not have an unreleased 0.4.5 version")

          # Should have the release date
          assert_match(/\[0.4.5\] - 2025-11-20/, contents,
            "Should have 0.4.5 with release date")

          # Should include both existing changes and git trailer changes
          assert_match(/Existing feature from changelog/, contents,
            "Should preserve existing changelog entries")
          assert_match(/Feature from git trailer/, contents,
            "Should include git trailer entries")
          assert_match(/Bug fix from git trailer/, contents,
            "Should include git trailer entries")

          # Should still have 0.4.4
          assert_match(/\[0.4.4\] - 2025-10-17/, contents,
            "Should preserve 0.4.4 version")

          # Should have unique entries (no duplicates)
          added_section = contents[/### Added\n(.*?)(?=###|\z)/m, 1]
          entries = added_section.scan(/^- (.+)$/).flatten
          assert_equal entries.uniq, entries,
            "Should not have duplicate entries in Added section"
        end
      end
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

    it "forwards tag_pattern to the git fragment handler" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          setup_git_repo_with_custom_tag("v2026.02.A")
          create_commit_with_trailer(
            "Post-release fix",
            "Fixed: Bug found after release"
          )

          File.write("CHANGELOG.md", <<~MD)
            # Changelog

            ## [2026.02.B] - Unreleased

            ## [2026.02.A] - 2026-02-24

            ### Added

            - Initial release
          MD

          tag_pattern =
            /^v(\d+\.\d+\.([A-Z]+|\d+))$/
          Reissue.finalize(
            "2026-02-25",
            changelog_file: "CHANGELOG.md",
            fragment: :git,
            tag_pattern:
          )

          contents = File.read("CHANGELOG.md")
          assert_match(
            /Bug found after release/, contents,
            "Should include post-tag trailer"
          )
          assert_match(
            /\[2026\.02\.B\] - 2026-02-25/, contents,
            "Should be finalized with date"
          )
        end
      end
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

  def setup
    @original_dir = Dir.pwd
  end

  def teardown
    Dir.chdir(@original_dir)
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

  private

  def setup_git_repo_with_custom_tag(tag)
    system("git init", out: File::NULL, err: File::NULL)
    system(
      "git config user.name 'Test User'",
      out: File::NULL, err: File::NULL
    )
    system(
      "git config user.email 'test@example.com'",
      out: File::NULL, err: File::NULL
    )
    File.write("README.md", "Initial")
    system("git add .", out: File::NULL, err: File::NULL)
    system(
      "git commit -m 'Initial release'",
      out: File::NULL, err: File::NULL
    )
    system("git tag #{tag}")
  end

  def create_commit_with_trailer(subject, trailer)
    filename = "test_#{Time.now.to_f}.txt"
    File.write(filename, "content")
    system(
      "git add #{filename}",
      out: File::NULL, err: File::NULL
    )
    Tempfile.create("commit_msg") do |f|
      f.write("#{subject}\n\n#{trailer}")
      f.flush
      system(
        "git commit -F #{f.path}",
        out: File::NULL, err: File::NULL
      )
    end
  end
end
