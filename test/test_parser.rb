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
          "Added" => ["New feature", "More things"],
          "Fixed" => ["Bug fix"]
        },
        changes.dig("versions", 1, "changes")
      )
    end
  end
end
