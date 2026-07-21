# frozen_string_literal: true

require "test_helper"
require "reissue/runbook"

class TestRunbook < Minitest::Spec
  before do
    @tempfile = Tempfile.new(["runbook", ".md"])
    @runbook = Reissue::Runbook.new(@tempfile.path)
  end

  after do
    @tempfile.close!
  end

  describe "generate" do
    it "writes a header-only template for an unreleased version" do
      @runbook.generate

      contents = File.read(@tempfile.path)
      assert_match(/# Runbook/, contents)
      assert_match(/Steps to perform after releasing the version below\./, contents)
      assert_match(/## \[Unreleased\]/, contents)
      refute_match(/- \[ \]/, contents)
    end
  end

  describe "clear" do
    it "resets a finalized runbook to the unreleased template" do
      @runbook.finalize(version: "1.2.3", date: "2026-07-21", trailer_items: ["Run cleanup (abc1234)"])
      @runbook.clear

      contents = File.read(@tempfile.path)
      assert_match(/## \[Unreleased\]/, contents)
      refute_match(/1\.2\.3/, contents)
      refute_match(/Run cleanup/, contents)
    end
  end

  describe "items" do
    it "returns an empty array for a header-only runbook" do
      @runbook.generate

      assert_empty @runbook.items
    end

    it "returns an empty array when the file does not exist" do
      runbook = Reissue::Runbook.new(File.join(Dir.mktmpdir, "RUNBOOK.md"))

      assert_empty runbook.items
    end

    it "parses unchecked, checked, and plain bullet items" do
      File.write(@tempfile.path, <<~MD)
        # Runbook

        Steps to perform after releasing the version below.

        ## [Unreleased]

        - [ ] Run `rake data:cleanup`
        - [x] Re-index search documents
        - Notify the support team
      MD

      assert_equal [
        "Run `rake data:cleanup`",
        "Re-index search documents",
        "Notify the support team"
      ], @runbook.items
    end
  end

  describe "finalize" do
    it "stamps the header with the version and date" do
      @runbook.generate
      @runbook.finalize(version: "1.2.3", date: "2026-07-21")

      contents = File.read(@tempfile.path)
      assert_match(/## \[1\.2\.3\] - 2026-07-21/, contents)
      refute_match(/Unreleased/, contents)
    end

    it "writes trailer items as unchecked checklist entries" do
      @runbook.generate
      @runbook.finalize(version: "1.2.3", date: "2026-07-21", trailer_items: ["Run cleanup (abc1234)"])

      contents = File.read(@tempfile.path)
      assert_match(/- \[ \] Run cleanup \(abc1234\)/, contents)
    end

    it "merges directly edited items with trailer items" do
      File.write(@tempfile.path, <<~MD)
        # Runbook

        Steps to perform after releasing the version below.

        ## [Unreleased]

        - [ ] Manually added step
      MD
      @runbook.finalize(version: "1.2.3", date: "2026-07-21", trailer_items: ["Run cleanup (abc1234)"])

      contents = File.read(@tempfile.path)
      assert_match(/- \[ \] Manually added step/, contents)
      assert_match(/- \[ \] Run cleanup \(abc1234\)/, contents)
    end

    it "deduplicates items by text" do
      File.write(@tempfile.path, <<~MD)
        # Runbook

        Steps to perform after releasing the version below.

        ## [Unreleased]

        - [ ] Run cleanup (abc1234)
      MD
      @runbook.finalize(version: "1.2.3", date: "2026-07-21", trailer_items: ["Run cleanup (abc1234)"])

      contents = File.read(@tempfile.path)
      assert_equal 1, contents.scan("Run cleanup (abc1234)").count
    end

    it "preserves checked state of directly edited items" do
      File.write(@tempfile.path, <<~MD)
        # Runbook

        Steps to perform after releasing the version below.

        ## [Unreleased]

        - [x] Already done step
      MD
      @runbook.finalize(version: "1.2.3", date: "2026-07-21", trailer_items: ["Already done step"])

      contents = File.read(@tempfile.path)
      assert_match(/- \[x\] Already done step/, contents)
      assert_equal 1, contents.scan("Already done step").count
    end

    it "is idempotent when run twice with the same trailer items" do
      @runbook.generate
      2.times do
        @runbook.finalize(version: "1.2.3", date: "2026-07-21", trailer_items: ["Run cleanup (abc1234)"])
      end

      contents = File.read(@tempfile.path)
      assert_equal 1, contents.scan("Run cleanup (abc1234)").count
      assert_equal 1, contents.scan("## [1.2.3] - 2026-07-21").count
    end

    it "bootstraps a missing file" do
      path = File.join(Dir.mktmpdir, "RUNBOOK.md")
      runbook = Reissue::Runbook.new(path)
      runbook.finalize(version: "1.2.3", date: "2026-07-21", trailer_items: ["Run cleanup (abc1234)"])

      contents = File.read(path)
      assert_match(/# Runbook/, contents)
      assert_match(/## \[1\.2\.3\] - 2026-07-21/, contents)
      assert_match(/- \[ \] Run cleanup \(abc1234\)/, contents)
    end

    it "stamps the header even with no items" do
      @runbook.generate
      @runbook.finalize(version: "1.2.3", date: "2026-07-21")

      contents = File.read(@tempfile.path)
      assert_match(/## \[1\.2\.3\] - 2026-07-21/, contents)
    end
  end
end
