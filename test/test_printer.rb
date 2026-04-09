# frozen_string_literal: true

require "test_helper"

class TestPrinter < Minitest::Spec
  describe "to_s" do
    it "returns a formatted changelog" do
      changelog = {
        "title" => "Changelog",
        "preamble" => "This is a changelog.",
        "versions" => [
          {
            "version" => "1.0.1",
            "date" => "Unreleased"
          },
          {
            "version" => "1.0.0",
            "date" => "2021-01-01",
            "changes" => {
              "Added" => ["New feature"]
            }
          }
        ]
      }
      printer = Reissue::Printer.new(changelog)
      assert_equal(<<~MARKDOWN, printer.to_s)
        # Changelog

        This is a changelog.

        ## [1.0.1] - Unreleased

        ## [1.0.0] - 2021-01-01

        ### Added

        - New feature
      MARKDOWN
    end

    it "handles empty changelogs" do
      changelog = {
        "versions" => []
      }
      printer = Reissue::Printer.new(changelog)
      assert_equal(<<~MARKDOWN, printer.to_s)
        # Changelog

        All project changes are documented in this file.

        ## [0.0.0] - Unreleased
      MARKDOWN
    end

    it "prints Unreleased version without date suffix" do
      changelog = {
        "title" => "Changelog",
        "preamble" => "This is a changelog.",
        "versions" => [
          {
            "version" => "Unreleased",
            "date" => nil
          },
          {
            "version" => "1.0.0",
            "date" => "2021-01-01",
            "changes" => {
              "Added" => ["New feature"]
            }
          }
        ]
      }
      printer = Reissue::Printer.new(changelog)
      result = printer.to_s
      assert_match(/## \[Unreleased\]\n/, result)
      refute_match(/## \[Unreleased\] -/, result)
    end

    it "handles nil versions" do
      changelog = {}
      printer = Reissue::Printer.new(changelog)
      assert_equal(<<~MARKDOWN, printer.to_s)
        # Changelog

        All project changes are documented in this file.

        ## [0.0.0] - Unreleased
      MARKDOWN
    end

    it "orders change sections by Reissue.changelog_sections, not hash insertion order" do
      saved = Reissue.changelog_sections.dup
      Reissue.changelog_sections = %w[Security Fixed Added Changed]

      changelog = {
        "versions" => [
          {
            "version" => "1.0.0",
            "date" => "2021-01-01",
            "changes" => {
              "Added" => ["feature"],
              "Security" => ["cve"],
              "Fixed" => ["bug"]
            }
          }
        ]
      }
      printer = Reissue::Printer.new(changelog)
      body = printer.to_s
      assert_operator body.index("### Security"), :<, body.index("### Fixed")
      assert_operator body.index("### Fixed"), :<, body.index("### Added")
    ensure
      Reissue.changelog_sections = saved
    end
  end
end
