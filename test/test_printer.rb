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
  end
end
