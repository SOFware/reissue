# frozen_string_literal: true

require "test_helper"

class TestParser < Minitest::Spec
  describe "parse" do
    it "parses a changelog" do
      changelog = File.read("test/fixtures/changelog.md")

      changes = Reissue::Parser.parse(changelog)

      assert_equal(
        "Change Log",
        changes["title"]
      )

      assert_equal(
        <<~TEXT.strip,
          All notable changes to this project will be documented in this file.

          The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
          and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
        TEXT
        changes["preamble"]
      )

      assert_equal(
        3,
        changes["versions"].size
      )

      assert_equal(
        "0.1.2",
        changes.dig("versions", 0, "version")
      )
      assert_equal(
        "Unreleased",
        changes.dig("versions", 0, "date")
      )
      assert_equal(
        "0.1.1",
        changes.dig("versions", 1, "version")
      )
      assert_equal(
        "2017-06-20",
        changes.dig("versions", 1, "date")
      )

      assert_equal(
        {
          "Added" => ["New feature", "More things\n  with extra lines"],
          "Fixed" => ["Bug fix"]
        },
        changes.dig("versions", 1, "changes")
      )
    end

    it "parses a changelog with an Unreleased version (no date)" do
      changelog = <<~MD
        # Changelog

        All notable changes.

        ## [Unreleased]

        ### Added

        - New feature in progress

        ## [1.0.0] - 2026-01-01

        ### Added

        - Initial release
      MD

      changes = Reissue::Parser.parse(changelog)

      assert_equal "Unreleased", changes.dig("versions", 0, "version")
      assert_nil changes.dig("versions", 0, "date")
      assert_equal ["New feature in progress"], changes.dig("versions", 0, "changes", "Added")
      assert_equal "1.0.0", changes.dig("versions", 1, "version")
      assert_equal "2026-01-01", changes.dig("versions", 1, "date")
    end

    it "handles files without an empty last line" do
      changelog = File.read("test/fixtures/changelog.md").chomp

      # It still parses
      changes = Reissue::Parser.parse(changelog)

      assert_equal(
        "Change Log",
        changes["title"]
      )
    end
  end
end
