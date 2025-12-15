# frozen_string_literal: true

require "test_helper"
require "rake"
require "stringio"
require "tmpdir"

class TestRakeBranchNaming < Minitest::Test
  def setup
    @rake = Rake::Application.new
    Rake.application = @rake
  end

  def teardown
    Rake.application.clear
  end

  def test_finalize_uses_finalize_prefix_for_branch_name
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_changelog("0.4.5")

        create_rakefile
        load "Rakefile"

        # Capture all output
        capture_io do
          Rake::Task["reissue:finalize"].invoke("2025-11-21")
        end

        # Check which branch was created
        current_branch = `git branch --show-current 2>/dev/null`.strip

        # Should use "finalize/" prefix with the version being finalized
        assert_equal "finalize/0.4.5", current_branch,
          "Finalize task should create branch with 'finalize/' prefix"

        # Verify changelog was finalized correctly
        changelog_content = File.read("CHANGELOG.md")
        assert_match(/## \[0\.4\.5\] - 2025-11-21/, changelog_content)
      end
    end
  end

  def test_reissue_uses_reissue_prefix_for_branch_name
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("0.4.5")

        create_rakefile
        load "Rakefile"

        # Capture all output
        capture_io do
          Rake::Task["reissue"].invoke("patch")
        end

        current_branch = `git branch --show-current 2>/dev/null`.strip

        # Should use "reissue/" prefix with the new version
        assert_equal "reissue/0.4.6", current_branch,
          "Reissue task should create branch with 'reissue/' prefix and new version"

        # Verify version was bumped
        version_content = File.read("version.rb")
        assert_match(/VERSION = "0\.4\.6"/, version_content)
      end
    end
  end

  def test_finalize_and_reissue_use_different_prefixes
    # This test documents that finalize uses "finalize/" prefix
    # and reissue uses "reissue/" prefix, preventing branch name conflicts
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_changelog("0.4.5")

        create_rakefile
        load "Rakefile"

        # Finalize creates branch with "finalize/" prefix
        capture_io do
          Rake::Task["reissue:finalize"].invoke("2025-11-21")
        end
        finalize_branch = `git branch --show-current 2>/dev/null`.strip
        assert_equal "finalize/0.4.5", finalize_branch

        # Reissue creates branch with "reissue/" prefix
        system("git checkout main", out: File::NULL, err: File::NULL)
        Rake.application.clear
        @rake = Rake::Application.new
        Rake.application = @rake
        load "Rakefile"

        capture_io do
          Rake::Task["reissue"].invoke("patch")
        end
        reissue_branch = `git branch --show-current 2>/dev/null`.strip
        assert_equal "reissue/0.4.6", reissue_branch

        # Different prefixes mean no conflicts
        refute_equal finalize_branch, reissue_branch
        assert_match %r{^finalize/}, finalize_branch
        assert_match %r{^reissue/}, reissue_branch
      end
    end
  end

  private

  def setup_git_repo_with_version(version)
    system("git init", out: File::NULL, err: File::NULL)
    system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
    system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

    # Create a bare repository to use as a fake remote
    system("git init --bare ../remote.git", out: File::NULL, err: File::NULL)
    system("git remote add origin ../remote.git", out: File::NULL, err: File::NULL)

    # Create version file
    File.write("version.rb", "VERSION = \"#{version}\"")

    # Create basic changelog
    File.write("CHANGELOG.md", <<~CHANGELOG)
      # Changelog

      ## [#{version}] - Unreleased

      ## [0.4.4] - 2025-11-20

      ### Added

      - Some feature
    CHANGELOG

    system("git add .", out: File::NULL, err: File::NULL)
    system("git commit -m 'Initial setup'", out: File::NULL, err: File::NULL)
    system("git branch -M main", out: File::NULL, err: File::NULL)
    system("git push -u origin main", out: File::NULL, err: File::NULL)
    system("git tag v#{version}", out: File::NULL, err: File::NULL)
  end

  def setup_git_repo_with_changelog(changelog_version)
    system("git init", out: File::NULL, err: File::NULL)
    system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
    system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

    # Create a bare repository to use as a fake remote
    system("git init --bare ../remote.git", out: File::NULL, err: File::NULL)
    system("git remote add origin ../remote.git", out: File::NULL, err: File::NULL)

    # Create version file (already bumped)
    File.write("version.rb", "VERSION = \"#{changelog_version}\"")

    # Create changelog with version as Unreleased (before finalize)
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
        # Create branches for testing but override push to avoid conflicts
        task.push_finalize = :branch
        task.push_reissue = :branch
      end

      # Override push task for testing - these tests only verify branch names
      Rake::Task["reissue:push"].clear
      task "reissue:push" do
        # No-op in tests - we're only testing branch creation
      end
    RUBY
  end
end
