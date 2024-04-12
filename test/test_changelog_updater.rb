# frozen_string_literal: true

require "test_helper"

class TestChangelogUpdater < Minitest::Spec
  describe "call" do
    before do
      @file = File.expand_path("fixtures/CHANGELOG.md", __dir__)
      @tempfile = Tempfile.new
      @changelog_updater = Reissue::ChangelogUpdater.new(@file)
    end

    it "updates the contents of the changelog file" do
      @changelog_updater.call("1.0.0", date: "2020-01-01", changes: {"Added" => ["Feature 1"]}, changelog_file: @tempfile.path)
      contents = @changelog_updater.to_s
      assert_match(/# 1.0.0/, contents)
      assert_match(/2020-01-01/, contents)
      assert_match(/Added/, contents)
      assert_match(/Feature 1/, contents)
    end

    it "Updates the changelog with default values for unreleased versions" do
      @changelog_updater.call("1.0.0", changelog_file: @tempfile.path)
      contents = @changelog_updater.to_s
      assert_match(/[1.0] - Unreleased/, contents)
    end

    it "Updates the changelog with a new date for the current version" do
      @changelog_updater.call("0.1.2", date: Date.today, changelog_file: @tempfile.path)
      contents = @changelog_updater.to_s
      assert_match(/#{Date.today}/, contents)
    end
  end

  describe "update" do
    before do
      @file = File.expand_path("fixtures/CHANGELOG.md", __dir__)
      @changelog_updater = Reissue::ChangelogUpdater.new(@file)
    end

    it "updates the contents of the changelog file" do
      @changelog_updater.update("1.0.0", date: "2020-01-01", changes: {"Added" => ["Feature 1"]})
      contents = @changelog_updater.to_s
      assert_match(/# 1.0.0/, contents)
      assert_match(/2020-01-01/, contents)
      assert_match(/Added/, contents)
      assert_match(/Feature 1/, contents)
    end

    it "Updates the changelog with default values for unreleased versions" do
      @changelog_updater.update("1.0.0")
      contents = @changelog_updater.to_s
      assert_match(/[1.0] - Unreleased/, contents)
    end

    it "Updates the changelog with a new date for the current version" do
      @changelog_updater.update("0.1.2", date: Date.today)
      contents = @changelog_updater.to_s
      assert_match(/#{Date.today}/, contents)
    end
  end

  describe "write" do
    before do
      @file = File.expand_path("fixtures/CHANGELOG.md", __dir__)
      @changelog_updater = Reissue::ChangelogUpdater.new(@file)
    end

    it "writes the contents of the changelog file" do
      @changelog_updater.update("1.0.0", date: "2020-01-01", changes: {"Added" => ["Feature 1"]})
      tempfile = Tempfile.new
      @changelog_updater.write(tempfile.path)
      contents = File.read(tempfile)
      assert_match(/# 1.0.0/, contents)
      assert_match(/2020-01-01/, contents)
      assert_match(/Added/, contents)
      assert_match(/Feature 1/, contents)
    end
  end
end
