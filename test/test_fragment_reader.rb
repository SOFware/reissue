# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class TestFragmentReader < Minitest::Spec
  describe "read" do
    before do
      @tmpdir = Dir.mktmpdir
      @fragment_dir = File.join(@tmpdir, "changelog.d")
      FileUtils.mkdir_p(@fragment_dir)
      @reader = Reissue::FragmentReader.new(@fragment_dir)
    end

    after do
      FileUtils.remove_entry @tmpdir
    end

    it "returns empty hash when fragment directory does not exist" do
      reader = Reissue::FragmentReader.new(File.join(@tmpdir, "nonexistent"))
      assert_equal({}, reader.read)
    end

    it "returns empty hash when no fragment files exist" do
      assert_equal({}, @reader.read)
    end

    it "reads and groups fragment files by section" do
      File.write(File.join(@fragment_dir, "123.added.md"), "New feature added")
      File.write(File.join(@fragment_dir, "124.fixed.md"), "Bug fix applied")
      File.write(File.join(@fragment_dir, "125.added.md"), "Another feature")

      fragments = @reader.read

      assert_equal 2, fragments.size
      assert_equal ["New feature added", "Another feature"], fragments["Added"]
      assert_equal ["Bug fix applied"], fragments["Fixed"]
    end

    it "ignores files with invalid naming format" do
      File.write(File.join(@fragment_dir, "invalid.md"), "Invalid file")
      File.write(File.join(@fragment_dir, "123.md"), "Missing section")
      File.write(File.join(@fragment_dir, "123.added.txt"), "Wrong extension")

      assert_equal({}, @reader.read)
    end

    it "ignores files with invalid sections" do
      File.write(File.join(@fragment_dir, "123.invalid.md"), "Invalid section")
      assert_equal({}, @reader.read)
    end

    it "ignores empty fragment files" do
      File.write(File.join(@fragment_dir, "123.added.md"), "")
      File.write(File.join(@fragment_dir, "124.added.md"), "   \n   ")
      assert_equal({}, @reader.read)
    end

    it "capitalizes section names correctly" do
      File.write(File.join(@fragment_dir, "123.added.md"), "Feature")
      File.write(File.join(@fragment_dir, "124.changed.md"), "Change")
      File.write(File.join(@fragment_dir, "125.deprecated.md"), "Deprecation")
      File.write(File.join(@fragment_dir, "126.removed.md"), "Removal")
      File.write(File.join(@fragment_dir, "127.fixed.md"), "Fix")
      File.write(File.join(@fragment_dir, "128.security.md"), "Security update")

      fragments = @reader.read

      assert fragments.key?("Added")
      assert fragments.key?("Changed")
      assert fragments.key?("Deprecated")
      assert fragments.key?("Removed")
      assert fragments.key?("Fixed")
      assert fragments.key?("Security")
    end

    it "strips whitespace from fragment content" do
      File.write(File.join(@fragment_dir, "123.added.md"), "  \n  Feature with spaces  \n  ")
      fragments = @reader.read
      assert_equal ["Feature with spaces"], fragments["Added"]
    end

    it "accepts custom valid sections" do
      reader = Reissue::FragmentReader.new(@fragment_dir, valid_sections: %w[feature bugfix])
      File.write(File.join(@fragment_dir, "123.feature.md"), "New feature")
      File.write(File.join(@fragment_dir, "124.bugfix.md"), "Bug fix")
      File.write(File.join(@fragment_dir, "125.added.md"), "This should be ignored")

      fragments = reader.read

      assert_equal 2, fragments.size
      assert_equal ["New feature"], fragments["Feature"]
      assert_equal ["Bug fix"], fragments["Bugfix"]
      refute fragments.key?("Added")
    end

    it "allows all sections when valid_sections is nil" do
      reader = Reissue::FragmentReader.new(@fragment_dir, valid_sections: nil)
      File.write(File.join(@fragment_dir, "123.custom.md"), "Custom section")
      File.write(File.join(@fragment_dir, "124.anything.md"), "Anything section")

      fragments = reader.read

      assert_equal 2, fragments.size
      assert_equal ["Custom section"], fragments["Custom"]
      assert_equal ["Anything section"], fragments["Anything"]
    end

    it "handles case-insensitive section matching" do
      reader = Reissue::FragmentReader.new(@fragment_dir, valid_sections: %w[Added FIXED])
      File.write(File.join(@fragment_dir, "123.added.md"), "Feature")
      File.write(File.join(@fragment_dir, "124.ADDED.md"), "Another feature")
      File.write(File.join(@fragment_dir, "125.fixed.md"), "Fix")
      File.write(File.join(@fragment_dir, "126.FIXED.md"), "Another fix")

      fragments = reader.read

      assert_equal 2, fragments.size
      assert_equal ["Feature", "Another feature"], fragments["Added"]
      assert_equal ["Fix", "Another fix"], fragments["Fixed"]
    end

    it "ignores all sections when valid_sections is empty array" do
      reader = Reissue::FragmentReader.new(@fragment_dir, valid_sections: [])
      File.write(File.join(@fragment_dir, "123.added.md"), "Feature")
      File.write(File.join(@fragment_dir, "124.fixed.md"), "Fix")

      fragments = reader.read

      assert_equal({}, fragments)
    end
  end

  describe "clear" do
    before do
      @tmpdir = Dir.mktmpdir
      @fragment_dir = File.join(@tmpdir, "changelog.d")
      FileUtils.mkdir_p(@fragment_dir)
      @reader = Reissue::FragmentReader.new(@fragment_dir)
    end

    after do
      FileUtils.remove_entry @tmpdir
    end

    it "does nothing when fragment directory does not exist" do
      reader = Reissue::FragmentReader.new(File.join(@tmpdir, "nonexistent"))
      assert_nil reader.clear
    end

    it "deletes all fragment files" do
      File.write(File.join(@fragment_dir, "123.added.md"), "Feature")
      File.write(File.join(@fragment_dir, "124.fixed.md"), "Fix")
      File.write(File.join(@fragment_dir, "other.txt"), "Other file")

      @reader.clear

      # Fragment files should be deleted
      refute File.exist?(File.join(@fragment_dir, "123.added.md"))
      refute File.exist?(File.join(@fragment_dir, "124.fixed.md"))

      # Non-fragment files should remain
      assert File.exist?(File.join(@fragment_dir, "other.txt"))

      # Directory should still exist
      assert Dir.exist?(@fragment_dir)
    end
  end
end
