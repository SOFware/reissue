# frozen_string_literal: true

require "test_helper"
require "fileutils"

class TestDeferredVersioningIntegration < Minitest::Spec
  before do
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)

    system("git init -q && git config user.name 'Test' && git config user.email 'test@test.com'", out: File::NULL, err: File::NULL)

    FileUtils.mkdir_p("lib/myapp")
    File.write("lib/myapp/version.rb", <<~RUBY)
      module MyApp
        VERSION = "1.0.0"
        RELEASE_DATE = "2026-03-01"
      end
    RUBY

    File.write("CHANGELOG.md", <<~MD)
      # Changelog

      All notable changes.

      ## [1.0.0] - 2026-03-01

      ### Added

      - Initial release
    MD

    system("git add . && git commit -q -m 'Release 1.0.0'", out: File::NULL, err: File::NULL)
    system("git tag v1.0.0")
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.remove_entry @tmpdir
  end

  describe "full deferred workflow" do
    it "post-release sets Unreleased, finalize resolves version from segment" do
      # Step 1: Post-release (deferred)
      Reissue.deferred_call(
        version_file: "lib/myapp/version.rb",
        changelog_file: "CHANGELOG.md",
        version_limit: 5
      )

      # Verify post-release state
      version_contents = File.read("lib/myapp/version.rb")
      assert_match(/VERSION = "Unreleased"/, version_contents)
      assert_match(/RELEASE_DATE = "Unreleased"/, version_contents)

      changelog_contents = File.read("CHANGELOG.md")
      assert_match(/## \[Unreleased\]\n/, changelog_contents)
      assert_match(/## \[1.0.0\] - 2026-03-01/, changelog_contents)

      # Step 2: Finalize with segment
      version, date = Reissue.deferred_finalize(
        "2026-03-06",
        segment: "minor",
        changelog_file: "CHANGELOG.md",
        version_file: "lib/myapp/version.rb"
      )

      assert_equal "1.1.0", version
      assert_equal "2026-03-06", date

      # Verify final state
      version_contents = File.read("lib/myapp/version.rb")
      assert_match(/VERSION = "1.1.0"/, version_contents)
      assert_match(/RELEASE_DATE = "2026-03-06"/, version_contents)

      changelog_contents = File.read("CHANGELOG.md")
      assert_match(/\[1.1.0\] - 2026-03-06/, changelog_contents)
      refute_match(/Unreleased/, changelog_contents)
    end

    it "finalize resolves version from explicit version string" do
      Reissue.deferred_call(
        version_file: "lib/myapp/version.rb",
        changelog_file: "CHANGELOG.md",
        version_limit: 5
      )

      version, _ = Reissue.deferred_finalize(
        "2026-03-06",
        version: "2.0.0",
        changelog_file: "CHANGELOG.md",
        version_file: "lib/myapp/version.rb"
      )

      assert_equal "2.0.0", version

      version_contents = File.read("lib/myapp/version.rb")
      assert_match(/VERSION = "2.0.0"/, version_contents)

      changelog_contents = File.read("CHANGELOG.md")
      assert_match(/\[2.0.0\] - 2026-03-06/, changelog_contents)
      refute_match(/Unreleased/, changelog_contents)
    end

    it "finalize resolves version from git trailers when using git fragments" do
      Reissue.deferred_call(
        version_file: "lib/myapp/version.rb",
        changelog_file: "CHANGELOG.md",
        version_limit: 5
      )

      system("git add . && git commit -q -m 'Prepare for development'", out: File::NULL, err: File::NULL)

      # Simulate development commits with trailers
      File.write("feature.rb", "# new feature")
      system("git add .", out: File::NULL, err: File::NULL)
      Tempfile.create("commit_msg") do |f|
        f.write("Add new feature\n\nAdded: Cool new feature\nVersion: minor")
        f.flush
        system("git commit -F #{f.path}", out: File::NULL, err: File::NULL)
      end

      version, _ = Reissue.deferred_finalize(
        "2026-03-06",
        changelog_file: "CHANGELOG.md",
        version_file: "lib/myapp/version.rb",
        fragment: :git
      )

      assert_equal "1.1.0", version

      changelog_contents = File.read("CHANGELOG.md")
      assert_match(/Cool new feature/, changelog_contents)
      assert_match(/\[1.1.0\] - 2026-03-06/, changelog_contents)
    end

    it "preserves existing changelog entries through the deferred workflow" do
      # Post-release with some manual changelog entries
      Reissue.deferred_call(
        version_file: "lib/myapp/version.rb",
        changelog_file: "CHANGELOG.md",
        version_limit: 5
      )

      # Manually add entries to the Unreleased section
      changelog = File.read("CHANGELOG.md")
      changelog.sub!("## [Unreleased]", "## [Unreleased]\n\n### Added\n\n- Manual feature\n- Another feature")
      File.write("CHANGELOG.md", changelog)

      # Finalize
      _, _ = Reissue.deferred_finalize(
        "2026-03-06",
        version: "1.1.0",
        changelog_file: "CHANGELOG.md",
        version_file: "lib/myapp/version.rb"
      )

      changelog_contents = File.read("CHANGELOG.md")
      assert_match(/Manual feature/, changelog_contents)
      assert_match(/Another feature/, changelog_contents)
      assert_match(/\[1.1.0\] - 2026-03-06/, changelog_contents)
    end
  end
end
