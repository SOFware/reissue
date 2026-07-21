# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class TestReissueRunbook < Minitest::Spec
  VERSION_FILE_CONTENT = <<~RUBY
    module Reissue
      module FakeGem
        VERSION = "0.1.0"
      end
    end
  RUBY

  CHANGELOG_CONTENT = <<~MD
    # Changelog

    All notable changes to this project will be documented in this file.

    ## [1.0.0] - Unreleased

    ### Added

    - New feature
  MD

  FINALIZED_RUNBOOK = <<~MD
    # Runbook

    Steps to perform after releasing the version below.

    ## [0.9.0] - 2026-01-01

    - [x] Old step
  MD

  describe ".call with runbook_file" do
    it "clears the runbook for the new unreleased version" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("version.rb", VERSION_FILE_CONTENT)
          File.write("CHANGELOG.md", CHANGELOG_CONTENT)
          File.write("RUNBOOK.md", FINALIZED_RUNBOOK)

          Reissue.call(version_file: "version.rb", changelog_file: "CHANGELOG.md", runbook_file: "RUNBOOK.md")

          contents = File.read("RUNBOOK.md")
          assert_match(/## \[Unreleased\]/, contents)
          refute_match(/0\.9\.0/, contents)
          refute_match(/Old step/, contents)
        end
      end
    end

    it "creates the runbook when it does not exist" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("version.rb", VERSION_FILE_CONTENT)
          File.write("CHANGELOG.md", CHANGELOG_CONTENT)

          Reissue.call(version_file: "version.rb", changelog_file: "CHANGELOG.md", runbook_file: "RUNBOOK.md")

          assert File.exist?("RUNBOOK.md")
          assert_match(/## \[Unreleased\]/, File.read("RUNBOOK.md"))
        end
      end
    end

    it "does not create a runbook when runbook_file is nil" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("version.rb", VERSION_FILE_CONTENT)
          File.write("CHANGELOG.md", CHANGELOG_CONTENT)

          Reissue.call(version_file: "version.rb", changelog_file: "CHANGELOG.md")

          refute File.exist?("RUNBOOK.md")
        end
      end
    end
  end

  describe ".finalize with runbook_file" do
    it "stamps the runbook with the changelog version and date, merging git trailers" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          setup_git_repo
          create_tag("v0.9.0")
          create_commit("Add cleanup\n\nRunbook: Run cleanup")

          File.write("CHANGELOG.md", CHANGELOG_CONTENT)
          File.write("RUNBOOK.md", <<~MD)
            # Runbook

            Steps to perform after releasing the version below.

            ## [Unreleased]

            - [ ] Manual step
          MD

          Reissue.finalize("2026-07-21", changelog_file: "CHANGELOG.md", runbook_file: "RUNBOOK.md")

          contents = File.read("RUNBOOK.md")
          assert_match(/## \[1\.0\.0\] - 2026-07-21/, contents)
          assert_match(/- \[ \] Manual step/, contents)
          assert_match(/- \[ \] Run cleanup \(\h{7,}\)/, contents)
        end
      end
    end

    it "stamps the runbook outside a git repository using direct edits only" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("CHANGELOG.md", CHANGELOG_CONTENT)
          File.write("RUNBOOK.md", <<~MD)
            # Runbook

            Steps to perform after releasing the version below.

            ## [Unreleased]

            - [ ] Manual step
          MD

          Reissue.finalize("2026-07-21", changelog_file: "CHANGELOG.md", runbook_file: "RUNBOOK.md")

          contents = File.read("RUNBOOK.md")
          assert_match(/## \[1\.0\.0\] - 2026-07-21/, contents)
          assert_match(/- \[ \] Manual step/, contents)
        end
      end
    end
  end

  describe ".deferred_call with runbook_file" do
    it "clears the runbook for the new unreleased version" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("version.rb", VERSION_FILE_CONTENT)
          File.write("CHANGELOG.md", CHANGELOG_CONTENT)
          File.write("RUNBOOK.md", FINALIZED_RUNBOOK)

          Reissue.deferred_call(version_file: "version.rb", changelog_file: "CHANGELOG.md", runbook_file: "RUNBOOK.md")

          contents = File.read("RUNBOOK.md")
          assert_match(/## \[Unreleased\]/, contents)
          refute_match(/Old step/, contents)
        end
      end
    end
  end

  describe ".deferred_finalize with runbook_file" do
    it "stamps the runbook with the resolved version" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write("CHANGELOG.md", <<~MD)
            # Changelog

            All notable changes to this project will be documented in this file.

            ## [Unreleased]

            ### Added

            - New feature
          MD
          File.write("RUNBOOK.md", <<~MD)
            # Runbook

            Steps to perform after releasing the version below.

            ## [Unreleased]

            - [ ] Manual step
          MD

          Reissue.deferred_finalize("2026-07-21", version: "2.0.0", changelog_file: "CHANGELOG.md", runbook_file: "RUNBOOK.md")

          contents = File.read("RUNBOOK.md")
          assert_match(/## \[2\.0\.0\] - 2026-07-21/, contents)
          assert_match(/- \[ \] Manual step/, contents)
        end
      end
    end
  end

  private

  def setup_git_repo
    system("git init", out: File::NULL, err: File::NULL)
    system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
    system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

    File.write("test.txt", "initial")
    system("git add test.txt", out: File::NULL, err: File::NULL)
    system("git commit -m 'Initial commit'", out: File::NULL, err: File::NULL)
  end

  def create_tag(tag_name)
    system("git tag -a #{tag_name} -m 'Release #{tag_name}'", out: File::NULL, err: File::NULL)
  end

  def create_commit(message)
    filename = "file_#{Time.now.to_f}.txt"
    File.write(filename, "content")
    system("git add #{filename}", out: File::NULL, err: File::NULL)
    system("git", "commit", "-m", message, out: File::NULL, err: File::NULL)
  end
end
