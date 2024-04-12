# frozen_string_literal: true

require "test_helper"

class TestReissue < Minitest::Spec
  describe "call" do
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

      fixture_changelog = File.expand_path("fixtures/CHANGELOG.md", __dir__)
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

  describe "finalize" do
    it "updates the contents of the changelog file" do
      fixture_changelog = File.expand_path("fixtures/CHANGELOG.md", __dir__)
      changelog_file = Tempfile.new
      changelog_file << File.read(fixture_changelog)
      changelog_file.close

      Reissue.finalize("2021-01-01", changelog_file: changelog_file.path)

      contents = File.read(changelog_file)

      assert_match(/0.1.2 - 2021-01-01/, contents)
    end
  end
end
