# frozen_string_literal: true

require "test_helper"

class TestChangelogUpdater < Minitest::Spec
  describe "call" do
    before do
      @file = File.expand_path("fixtures/changelog.md", __dir__)
      @tempfile = Tempfile.new
      @changelog_updater = Reissue::ChangelogUpdater.new(@file)
    end

    it "updates the contents of the changelog file" do
      @changelog_updater.call("1.0.0", date: "2020-01-01", changes: {"Added" => ["Feature 1"]}, changelog_file: @tempfile.path)
      contents = @changelog_updater.to_s
      assert_match(/# \[1.0.0\]/, contents)
      assert_match(/2020-01-01/, contents)
      assert_match(/Added/, contents)
      assert_match(/Feature 1/, contents)
    end

    it "Updates the changelog with default values for unreleased versions" do
      @changelog_updater.call("1.0.0", changelog_file: @tempfile.path)
      contents = @changelog_updater.to_s
      assert_match(/\[1.0\.0\] - Unreleased/, contents)
    end

    it "Updates the changelog with a new date for the current version" do
      @changelog_updater.call("0.1.2", date: Date.today, changelog_file: @tempfile.path)
      contents = @changelog_updater.to_s
      assert_match(/#{Date.today}/, contents)
    end

    it "limits the number of versions to keep" do
      @changelog_updater.call("1.0.0", changelog_file: @tempfile.path, version_limit: 1)
      @changelog_updater.call("1.1.0", changelog_file: @tempfile.path, version_limit: 1)
      contents = @changelog_updater.to_s
      assert_match(/\[1.1\.0\]/, contents)
      refute_match(/\[1.0\.0\]/, contents)
    end

    it "handles empty changelog files" do
      @changelog_updater = Reissue::ChangelogUpdater.new(@tempfile.path)
      @changelog_updater.call("1.0.0", changelog_file: @tempfile.path)
      contents = @changelog_updater.to_s
      assert_match(/\[1.0\.0\]/, contents)
    end
  end

  describe "update" do
    before do
      @file = File.expand_path("fixtures/changelog.md", __dir__)
      @changelog_updater = Reissue::ChangelogUpdater.new(@file)
    end

    it "updates the contents of the changelog file" do
      @changelog_updater.update("1.0.0", date: "2020-01-01", changes: {"Added" => ["Feature 1"]})
      contents = @changelog_updater.to_s
      assert_match(/# \[1.0.0\]/, contents)
      assert_match(/2020-01-01/, contents)
      assert_match(/Added/, contents)
      assert_match(/Feature 1/, contents)
    end

    it "Updates the changelog with default values for unreleased versions" do
      @changelog_updater.update("1.0.0")
      contents = @changelog_updater.to_s
      assert_match(/\[1.0.0\] - Unreleased/, contents)
    end

    it "Updates the changelog with a new date for the current version" do
      @changelog_updater.update("0.1.2", date: Date.today)
      contents = @changelog_updater.to_s
      assert_match(/#{Date.today}/, contents)
    end
  end

  describe "write" do
    before do
      @file = File.expand_path("fixtures/changelog.md", __dir__)
      @changelog_updater = Reissue::ChangelogUpdater.new(@file)
      @tempdir = Dir.mktmpdir
    end

    after do
      FileUtils.remove_entry @tempdir
    end

    it "writes the contents of the changelog file" do
      @changelog_updater.update("1.0.0", date: "2020-01-01", changes: {"Added" => ["Feature 1"]})
      tempfile = Tempfile.new
      @changelog_updater.write(tempfile.path)
      contents = File.read(tempfile)
      assert_match(/# \[1.0.0\]/, contents)
      assert_match(/2020-01-01/, contents)
      assert_match(/Added/, contents)
      assert_match(/Feature 1/, contents)
    end

    it "retains changelogs using a custom proc" do
      custom_path = File.join(@tempdir, "custom.md")
      retention_proc = ->(version, content) { File.write(custom_path, content) }

      @changelog_updater.update("2.0.0", changes: {"Added" => ["Feature 2"]})
      @changelog_updater.write(custom_path, retain_changelogs: retention_proc)

      assert File.exist?(custom_path)
      contents = File.read(custom_path)
      assert_match(/# \[2.0.0\]/, contents)
      assert_match(/Feature 2/, contents)
    end
  end

  describe "update with fragments" do
    before do
      @file = File.expand_path("fixtures/changelog.md", __dir__)
      @changelog_updater = Reissue::ChangelogUpdater.new(@file)
      @tmpdir = Dir.mktmpdir
      @fragment_dir = File.join(@tmpdir, "changelog.d")
      FileUtils.mkdir_p(@fragment_dir)
    end

    after do
      FileUtils.remove_entry @tmpdir
    end

    it "merges fragment changes with provided changes" do
      File.write(File.join(@fragment_dir, "123.added.md"), "Fragment feature")
      File.write(File.join(@fragment_dir, "124.fixed.md"), "Fragment fix")

      @changelog_updater.update(
        "1.0.0",
        date: "2020-01-01",
        changes: {"Added" => ["Manual feature"]},
        fragment_directory: @fragment_dir
      )

      contents = @changelog_updater.to_s
      assert_match(/Manual feature/, contents)
      assert_match(/Fragment feature/, contents)
      assert_match(/Fragment fix/, contents)
    end

    it "creates sections from fragments when not in provided changes" do
      File.write(File.join(@fragment_dir, "123.security.md"), "Security patch")

      @changelog_updater.update(
        "1.0.0",
        changes: {"Added" => ["New feature"]},
        fragment_directory: @fragment_dir
      )

      contents = @changelog_updater.to_s
      assert_match(/### Added/, contents)
      assert_match(/### Security/, contents)
      assert_match(/Security patch/, contents)
    end
  end

  describe "call with fragments" do
    before do
      @file = File.expand_path("fixtures/changelog.md", __dir__)
      @tempfile = Tempfile.new
      @changelog_updater = Reissue::ChangelogUpdater.new(@file)
      @tmpdir = Dir.mktmpdir
      @fragment_dir = File.join(@tmpdir, "changelog.d")
      FileUtils.mkdir_p(@fragment_dir)
    end

    after do
      FileUtils.remove_entry @tmpdir
    end

    it "preserves fragments after updating changelog" do
      File.write(File.join(@fragment_dir, "123.added.md"), "Feature")

      @changelog_updater.call(
        "1.0.0",
        changelog_file: @tempfile.path,
        fragment_directory: @fragment_dir
      )

      assert File.exist?(File.join(@fragment_dir, "123.added.md"))
    end
  end

  describe "reformat" do
    before do
      @file = File.expand_path("fixtures/changelog.md", __dir__)
      @changelog_updater = Reissue::ChangelogUpdater.new(@file)
    end

    it "reformats the contents of the changelog file" do
      changelog = <<~FILE.chomp
        # CHANGELOG
        All updates to the application will be tracked here per released version.
        ## [2024.1.A] - Unreleased
        ### Added
        - Tasks for automating the updates to version and changelog.
      FILE
      tempfile = Tempfile.new
      File.write(tempfile, changelog)

      updater = Reissue::ChangelogUpdater.new(tempfile.path)
      updater.reformat
      contents = tempfile.read
      assert_equal(<<~FILE, contents)
        # CHANGELOG

        All updates to the application will be tracked here per released version.

        ## [2024.1.A] - Unreleased

        ### Added

        - Tasks for automating the updates to version and changelog.
      FILE
    end
  end
end
