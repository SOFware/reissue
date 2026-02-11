# frozen_string_literal: true

require "test_helper"

class TestChangelogSections < Minitest::Spec
  after do
    Reissue.changelog_sections = Reissue::DEFAULT_CHANGELOG_SECTIONS
  end

  describe "Reissue.changelog_sections" do
    it "returns the default sections" do
      assert_equal %w[Added Changed Deprecated Removed Fixed Security], Reissue.changelog_sections
    end

    it "returns a mutable copy of the default" do
      sections = Reissue.changelog_sections
      refute_same Reissue::DEFAULT_CHANGELOG_SECTIONS, sections
    end

    it "allows setting custom sections" do
      Reissue.changelog_sections = %w[Major Added Changed]
      assert_equal %w[Major Added Changed], Reissue.changelog_sections
    end

    it "capitalizes section names" do
      Reissue.changelog_sections = %w[major added CHANGED]
      assert_equal %w[Major Added Changed], Reissue.changelog_sections
    end

    it "removes duplicates" do
      Reissue.changelog_sections = %w[Added added ADDED Changed]
      assert_equal %w[Added Changed], Reissue.changelog_sections
    end

    it "is idempotent when prepending custom sections" do
      Reissue.changelog_sections = %w[Major] + Reissue.changelog_sections
      first_result = Reissue.changelog_sections.dup

      Reissue.changelog_sections = %w[Major] + Reissue.changelog_sections
      second_result = Reissue.changelog_sections

      assert_equal first_result, second_result
      assert_equal %w[Major Added Changed Deprecated Removed Fixed Security], first_result
    end

    it "wraps non-array values in an array" do
      Reissue.changelog_sections = "custom"
      assert_equal %w[Custom], Reissue.changelog_sections
    end
  end
end
