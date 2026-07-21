# frozen_string_literal: true

require "test_helper"
require "rake"
require "tmpdir"

class TestRakeRunbookFileOption < Minitest::Test
  def setup
    @rake = Rake::Application.new
    Rake.application = @rake
  end

  def teardown
    Rake.application.clear
  end

  def test_reissue_task_clears_runbook
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")
        write_changelog("1.2.3", date: "2026-07-01")
        File.write("RUNBOOK.md", <<~MD)
          # Runbook

          Steps to perform after releasing the version below.

          ## [1.2.3] - 2026-07-01

          - [ ] Old step
        MD
        commit_file("RUNBOOK.md", "Add runbook")

        create_rakefile(commit: false)
        load "Rakefile"

        capture_io { Rake::Task["reissue"].invoke("patch") }

        contents = File.read("RUNBOOK.md")
        assert_match(/## \[Unreleased\]/, contents)
        refute_match(/Old step/, contents)
      end
    end
  end

  def test_finalize_task_stamps_runbook_matching_changelog
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.4")
        write_changelog("1.2.4", date: "Unreleased")
        File.write("RUNBOOK.md", <<~MD)
          # Runbook

          Steps to perform after releasing the version below.

          ## [Unreleased]

          - [ ] Manual step
        MD
        commit_file("RUNBOOK.md", "Add runbook\n\nRunbook: Run `rake data:cleanup`")

        create_rakefile(commit_finalize: false)
        load "Rakefile"

        capture_io { Rake::Task["reissue:finalize"].invoke("2026-07-21") }

        runbook = File.read("RUNBOOK.md")
        changelog = File.read("CHANGELOG.md")
        assert_match(/## \[1\.2\.4\] - 2026-07-21/, changelog)
        assert_match(/## \[1\.2\.4\] - 2026-07-21/, runbook)
        assert_match(/- \[ \] Manual step/, runbook)
        assert_match(/- \[ \] Run `rake data:cleanup` \(\h{7,}\)/, runbook)
      end
    end
  end

  def test_finalize_task_commits_newly_created_runbook
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.4")
        write_changelog("1.2.4", date: "Unreleased")
        commit_file("CHANGELOG.md", "Update changelog")

        create_rakefile(commit_finalize: true)
        load "Rakefile"

        capture_io { Rake::Task["reissue:finalize"].invoke("2026-07-21") }

        assert File.exist?("RUNBOOK.md")
        status = `git status --porcelain`
        refute_match(/RUNBOOK\.md/, status, "RUNBOOK.md should be committed")
        committed_files = `git show --name-only --format= HEAD`
        assert_match(/RUNBOOK\.md/, committed_files)
      end
    end
  end

  def test_preview_task_shows_runbook_entries
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")
        commit_file("note.txt", "Add cleanup\n\nRunbook: Run the cleanup task")

        create_rakefile
        load "Rakefile"

        output, _ = capture_io { Rake::Task["reissue:preview"].invoke }

        assert_match(/Runbook items/, output)
        assert_match(/Run the cleanup task/, output)
      end
    end
  end

  private

  def setup_git_repo_with_version(version)
    system("git init", out: File::NULL, err: File::NULL)
    system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
    system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

    File.write("version.rb", "VERSION = \"#{version}\"")
    system("git add version.rb", out: File::NULL, err: File::NULL)
    system("git commit -m 'Initial version'", out: File::NULL, err: File::NULL)
    system("git tag v1.2.3", out: File::NULL, err: File::NULL)
  end

  def write_changelog(version, date:)
    File.write("CHANGELOG.md", <<~MD)
      # Changelog

      ## [#{version}] - #{date}

      ### Added

      - Existing feature
    MD
  end

  def commit_file(filename, message)
    File.write(filename, File.exist?(filename) ? File.read(filename) : "content") unless File.exist?(filename)
    system("git add #{filename}", out: File::NULL, err: File::NULL)
    system("git", "commit", "-m", message, out: File::NULL, err: File::NULL)
  end

  def create_rakefile(commit: false, commit_finalize: false)
    File.write("Rakefile", <<~RUBY)
      require "reissue/rake"

      Reissue::Task.create :reissue do |task|
        task.version_file = "version.rb"
        task.fragment = :git
        task.runbook_file = "RUNBOOK.md"
        task.commit = #{commit}
        task.commit_finalize = #{commit_finalize}
        task.push_reissue = false
        task.push_finalize = false
      end
    RUBY
  end
end
