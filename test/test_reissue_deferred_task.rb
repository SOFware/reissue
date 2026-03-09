# frozen_string_literal: true

require "test_helper"
require "reissue/rake"
require "rake"

class TestReissueDeferredTask < Minitest::Spec
  before do
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)

    system("git init -q && git config user.name 'Test' && git config user.email 'test@test.com'", out: File::NULL, err: File::NULL)

    FileUtils.mkdir_p("lib/test")
    File.write("lib/test/version.rb", <<~RUBY)
      module Test
        VERSION = "1.0.0"
        RELEASE_DATE = "2026-03-01"
      end
    RUBY

    File.write("CHANGELOG.md", <<~MD)
      # Changelog

      All notable changes.

      ## [1.0.0] - 2026-03-01

      ### Added

      - Initial release
    MD

    system("git add . && git commit -q -m 'Release 1.0.0'", out: File::NULL, err: File::NULL)
    system("git tag v1.0.0")

    Rake::Task.clear
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.remove_entry @tmpdir
  end

  describe "deferred_versioning configuration" do
    it "defaults to false" do
      task = Reissue::Task.create :reissue do |t|
        t.version_file = "lib/test/version.rb"
        t.commit = false
      end
      refute task.deferred_versioning
    end

    it "can be set to true" do
      task = Reissue::Task.create :reissue do |t|
        t.version_file = "lib/test/version.rb"
        t.deferred_versioning = true
        t.commit = false
      end
      assert task.deferred_versioning
    end
  end

  describe "deferred reissue task" do
    it "sets VERSION to Unreleased instead of bumping" do
      Reissue::Task.create :reissue do |t|
        t.version_file = "lib/test/version.rb"
        t.deferred_versioning = true
        t.commit = false
      end

      Rake::Task[:reissue].invoke

      version_contents = File.read("lib/test/version.rb")
      assert_match(/VERSION = "Unreleased"/, version_contents)

      changelog_contents = File.read("CHANGELOG.md")
      assert_match(/## \[Unreleased\]/, changelog_contents)
    end
  end

  describe "deferred finalize task" do
    it "resolves version from segment argument" do
      Reissue::Task.create :reissue do |t|
        t.version_file = "lib/test/version.rb"
        t.deferred_versioning = true
        t.commit = false
        t.commit_finalize = false
      end

      # First run deferred post-release
      Rake::Task[:reissue].invoke

      # Then finalize with segment
      Rake::Task["reissue:finalize"].invoke("patch")

      version_contents = File.read("lib/test/version.rb")
      assert_match(/VERSION = "1.0.1"/, version_contents)

      changelog_contents = File.read("CHANGELOG.md")
      assert_match(/\[1.0.1\]/, changelog_contents)
      refute_match(/Unreleased/, changelog_contents)
    end
  end
end
