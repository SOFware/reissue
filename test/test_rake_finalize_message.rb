# frozen_string_literal: true

require "test_helper"
require "rake"
require "tmpdir"

class TestRakeFinalizeMessage < Minitest::Test
  def setup
    @rake = Rake::Application.new
    Rake.application = @rake
  end

  def teardown
    Rake.application.clear
  end

  def test_default_subject_fits_a_fifty_character_commit_limit
    in_repo_with_changelog("2026.8.C") do
      create_rakefile
      load "Rakefile"

      capture_io do
        Rake::Task["reissue:finalize"].invoke("2026-09-17")
      end

      subject = `git log --format=%s -1`.strip

      assert_equal "Finalize changelog for 2026.8.C", subject
      assert_operator subject.length, :<=, 50
    end
  end

  def test_finalize_message_accepts_a_custom_callable
    in_repo_with_changelog("0.4.5") do
      File.write("Rakefile", <<~RUBY)
        require "reissue/rake"

        Reissue::Task.create :reissue do |task|
          task.version_file = "version.rb"
          task.fragment = :git
          task.push_finalize = false
          task.push_reissue = false
          task.finalize_message = ->(version, date) { "Release \#{version} (\#{date})" }
        end
      RUBY
      load "Rakefile"

      capture_io do
        Rake::Task["reissue:finalize"].invoke("2025-11-21")
      end

      assert_equal "Release 0.4.5 (2025-11-21)", `git log --format=%s -1`.strip
    end
  end

  private

  def in_repo_with_changelog(version)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_changelog(version)
        yield
      end
    end
  end

  def setup_git_repo_with_changelog(changelog_version)
    system("git init", out: File::NULL, err: File::NULL)
    system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
    system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)
    system("git init --bare ../remote.git", out: File::NULL, err: File::NULL)
    system("git remote add origin ../remote.git", out: File::NULL, err: File::NULL)

    File.write("version.rb", "VERSION = \"#{changelog_version}\"")
    File.write("CHANGELOG.md", <<~CHANGELOG)
      # Changelog

      ## [#{changelog_version}] - Unreleased

      ### Fixed

      - Some bug fix

      ## [0.4.4] - 2025-11-20

      ### Added

      - Some feature
    CHANGELOG

    system("git add .", out: File::NULL, err: File::NULL)
    system("git commit -m 'Initial setup'", out: File::NULL, err: File::NULL)
    system("git branch -M main", out: File::NULL, err: File::NULL)
    system("git push -u origin main", out: File::NULL, err: File::NULL)
  end

  def create_rakefile
    File.write("Rakefile", <<~RUBY)
      require "reissue/rake"

      Reissue::Task.create :reissue do |task|
        task.version_file = "version.rb"
        task.fragment = :git
        task.push_finalize = false
        task.push_reissue = false
      end
    RUBY
  end
end
