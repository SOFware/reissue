# frozen_string_literal: true

require "test_helper"

class TestVersionUpdater < Minitest::Spec
  describe "call" do
    before do
      @file = File.expand_path("fixtures/version.rb", __dir__)
      @tempfile = Tempfile.new
      @version_updater = Reissue::VersionUpdater.new(@file)
    end

    it "updates the contents of the version file" do
      @version_updater.call("major", version_file: @tempfile.path)
      contents = File.read(@tempfile.path)
      assert_match(/1.0.0/, contents)
    end
  end

  describe "update" do
    before do
      @file = File.expand_path("fixtures/version.rb", __dir__)
      @tempfile = Tempfile.new
      @version_updater = Reissue::VersionUpdater.new(@file)
    end

    it "updates the major version" do
      contents = @version_updater.update("major")
      assert_equal "1.0.0", contents
    end

    it "updates the minor version" do
      contents = @version_updater.update("minor")
      assert_equal "0.2.0", contents
    end

    it "updates the patch version" do
      contents = @version_updater.update("patch")
      assert_equal "0.1.1", contents
    end

    it "works with letters in the version string" do
      @file = File.expand_path("fixtures/alpha_version.rb", __dir__)
      @version_updater = Reissue::VersionUpdater.new(@file)
      contents = @version_updater.update("patch")
      assert_equal "0.1.C", contents
    end

    it "works with greek alphabet names" do
      @file = File.expand_path("fixtures/greek_version.rb", __dir__)
      @version_updater = Reissue::VersionUpdater.new(@file)
      contents = @version_updater.update("patch")
      assert_equal "2.32.gamma", contents
    end
  end
end
