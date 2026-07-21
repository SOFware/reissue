# frozen_string_literal: true

require "test_helper"
require "rake"
require "stringio"
require "tempfile"
require "tmpdir"

class TestRakeNextVersionTask < Minitest::Test
  def setup
    @rake = Rake::Application.new
    Rake.application = @rake
  end

  def teardown
    Rake.application.clear
  end

  def test_reports_version_the_minor_trailer_would_produce
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")
        create_commit_with_trailer("New feature", "Version: minor")

        create_rakefile
        load "Rakefile"

        output, _err = capture_io { Rake::Task["reissue:next_version"].invoke }

        assert_equal "1.3.0", output.strip
      end
    end
  end

  def test_reports_current_version_when_no_version_trailer_is_present
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")
        create_commit_with_trailer("Regular fix", "Fixed: Some bug")

        create_rakefile
        load "Rakefile"

        output, _err = capture_io { Rake::Task["reissue:next_version"].invoke }

        assert_equal "1.2.3", output.strip
      end
    end
  end

  # Mirrors reissue:bump, which derives the bump from the last tag and skips when
  # that lands at or below the version already in the file.
  def test_reports_current_version_when_the_trailer_would_not_advance_past_it
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.2")
        bump_version_file_to("1.2.3")
        create_commit_with_trailer("Bug fix", "Version: patch")

        create_rakefile
        load "Rakefile"

        output, _err = capture_io { Rake::Task["reissue:next_version"].invoke }

        # patch(v1.2.2) is 1.2.3, which the file already holds, so nothing moves
        assert_equal "1.2.3", output.strip
      end
    end
  end

  def test_derives_the_bump_from_the_last_tag_rather_than_the_version_file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.2")
        bump_version_file_to("1.5.0")
        create_commit_with_trailer("New feature", "Version: minor")

        create_rakefile
        load "Rakefile"

        output, _err = capture_io { Rake::Task["reissue:next_version"].invoke }

        # minor(v1.2.2) is 1.3.0, behind the file's 1.5.0, so the file wins
        assert_equal "1.5.0", output.strip
      end
    end
  end

  def test_leaves_the_version_file_and_working_tree_untouched
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")
        create_commit_with_trailer("New feature", "Version: minor")

        create_rakefile
        load "Rakefile"

        before = File.read("version.rb")
        status_before = `git status --porcelain`

        capture_io { Rake::Task["reissue:next_version"].invoke }

        assert_equal before, File.read("version.rb"), "next_version must not rewrite the version file"
        assert_equal status_before, `git status --porcelain`, "next_version must not alter the working tree"
      end
    end
  end

  def test_leaves_the_version_file_untouched_when_the_file_is_ahead_of_the_tag
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.2")
        bump_version_file_to("1.2.3")
        create_commit_with_trailer("New feature", "Version: minor")

        create_rakefile
        load "Rakefile"

        before = File.read("version.rb")
        status_before = `git status --porcelain`

        capture_io { Rake::Task["reissue:next_version"].invoke }

        assert_equal before, File.read("version.rb"), "next_version must not rewrite the version file"
        assert_equal status_before, `git status --porcelain`, "next_version must not alter the working tree"
      end
    end
  end

  # reissue:bump exits early unless fragment is :git, so git trailers cannot move
  # the version for a directory-fragment project and must not be reported as if
  # they would.
  def test_ignores_git_trailers_when_fragments_come_from_a_directory
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")
        create_commit_with_trailer("New feature", "Version: minor")

        create_rakefile_with_directory_fragments
        load "Rakefile"

        output, _err = capture_io { Rake::Task["reissue:next_version"].invoke }

        assert_equal "1.2.3", output.strip
      end
    end
  end

  # Under deferred versioning the version file holds "Unreleased" and the real
  # version is resolved at finalize time from the last tag plus the trailer.
  def test_resolves_from_the_tag_when_versioning_is_deferred
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.2")
        bump_version_file_to("Unreleased")
        create_commit_with_trailer("New feature", "Version: minor")

        create_rakefile_with_deferred_versioning
        load "Rakefile"

        output, _err = capture_io { Rake::Task["reissue:next_version"].invoke }

        assert_equal "1.3.0", output.strip
      end
    end
  end

  def test_explains_itself_when_deferred_versioning_has_nothing_to_resolve_from
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.2")
        bump_version_file_to("Unreleased")
        create_commit_with_trailer("Regular fix", "Fixed: Some bug")

        create_rakefile_with_deferred_versioning
        load "Rakefile"

        error = assert_raises(RuntimeError) do
          capture_io { Rake::Task["reissue:next_version"].invoke }
        end

        assert_match(/cannot determine the next version/i, error.message)
      end
    end
  end

  private

  def create_rakefile_with_deferred_versioning
    File.write("Rakefile", <<~RUBY)
      require "reissue/rake"

      Reissue::Task.create :reissue do |task|
        task.version_file = "version.rb"
        task.fragment = :git
        task.deferred_versioning = true
      end
    RUBY
  end

  def create_rakefile_with_directory_fragments
    Dir.mkdir("changelog_fragments")
    File.write("Rakefile", <<~RUBY)
      require "reissue/rake"

      Reissue::Task.create :reissue do |task|
        task.version_file = "version.rb"
        task.fragment = "changelog_fragments"
      end
    RUBY
  end

  def bump_version_file_to(version)
    File.write("version.rb", "VERSION = \"#{version}\"")
    system("git add version.rb", out: File::NULL, err: File::NULL)
    system("git commit -m 'Bump version to #{version}'", out: File::NULL, err: File::NULL)
  end

  def setup_git_repo_with_version(version)
    system("git init", out: File::NULL, err: File::NULL)
    system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
    system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

    File.write("version.rb", "VERSION = \"#{version}\"")
    system("git add version.rb", out: File::NULL, err: File::NULL)
    system("git commit -m 'Initial version'", out: File::NULL, err: File::NULL)
    system("git tag v#{version}", out: File::NULL, err: File::NULL)
  end

  def create_commit_with_trailer(subject, trailer)
    filename = "test_#{Time.now.to_f}.txt"
    File.write(filename, "content")
    system("git add #{filename}", out: File::NULL, err: File::NULL)

    message = "#{subject}\n\n#{trailer}"
    Tempfile.create("commit_msg") do |f|
      f.write(message)
      f.flush
      system("git commit -F #{f.path}", out: File::NULL, err: File::NULL)
    end
  end

  def create_rakefile
    File.write("Rakefile", <<~RUBY)
      require "reissue/rake"

      Reissue::Task.create :reissue do |task|
        task.version_file = "version.rb"
        task.fragment = :git
      end
    RUBY
  end
end
