# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "tempfile"

class GitFragmentIntegrationTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
  end

  def teardown
    Dir.chdir(@original_dir)
  end

  def test_full_release_workflow_with_git_trailers
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Initialize git repo
        system("git init", out: File::NULL, err: File::NULL)
        system("git config user.name 'Test User'", out: File::NULL, err: File::NULL)
        system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

        # Create initial version file
        version_file = "lib/test/version.rb"
        FileUtils.mkdir_p("lib/test")
        File.write(version_file, <<~RUBY)
          module Test
            VERSION = "1.0.0"
          end
        RUBY

        # Create initial changelog
        changelog_file = "CHANGELOG.md"
        File.write(changelog_file, <<~MD)
          # Changelog

          All notable changes to this project will be documented in this file.

          ## [1.0.0] - 2025-01-01

          ### Added
          - Initial release
        MD

        # Commit initial state and tag it
        system("git add .", out: File::NULL, err: File::NULL)
        system("git commit -m 'Initial release'", out: File::NULL, err: File::NULL)
        system("git tag v1.0.0", out: File::NULL, err: File::NULL)

        # Make commits with trailers
        create_commit_with_trailer("Fix bug", "Fixed: Critical bug in payment processing")
        create_commit_with_trailer("Add feature", "Added: New dashboard widget for analytics")
        create_commit_with_trailer("Update deps", "Changed: Updated Ruby version to 3.2")
        create_commit_with_trailer("Security patch", "Security: Fixed XSS vulnerability in user input")

        # Use Reissue to update changelog with git trailers
        version_updater = Reissue::VersionUpdater.new(version_file)
        new_version = version_updater.call("minor", version_file: version_file)

        changelog_updater = Reissue::ChangelogUpdater.new(changelog_file)
        changelog_updater.call(
          new_version,
          date: "Unreleased",
          changelog_file: changelog_file,
          version_limit: 2,
          retain_changelogs: false,
          fragment: :git
        )

        # Read the updated changelog
        updated_changelog = File.read(changelog_file)

        # Verify the changelog contains entries from git trailers
        assert_match(/### Added\n\n- New dashboard widget for analytics/, updated_changelog)
        assert_match(/### Changed\n\n- Updated Ruby version to 3.2/, updated_changelog)
        assert_match(/### Fixed\n\n- Critical bug in payment processing/, updated_changelog)
        assert_match(/### Security\n\n- Fixed XSS vulnerability in user input/, updated_changelog)

        # Verify version was updated
        assert_match(/## \[1\.1\.0\] - Unreleased/, updated_changelog)
      end
    end
  end

  def test_changelog_updater_with_git_fragment_handler
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Initialize git repo
        system("git init", out: File::NULL, err: File::NULL)
        system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
        system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

        # Create and tag initial version
        File.write("test.txt", "initial")
        system("git add test.txt", out: File::NULL, err: File::NULL)
        system("git commit -m 'Initial commit'", out: File::NULL, err: File::NULL)
        system("git tag v1.0.0", out: File::NULL, err: File::NULL)

        # Add commits with trailers
        create_commit_with_trailer("Fix", "Fixed: Memory leak issue")
        create_commit_with_trailer("Add", "Added: Export functionality")

        # Create a simple changelog
        changelog_content = <<~MD
          # Changelog

          ## [1.0.0] - 2025-01-01
          ### Added
          - Initial release
        MD
        File.write("CHANGELOG.md", changelog_content)

        # Update changelog using git fragments
        updater = Reissue::ChangelogUpdater.new("CHANGELOG.md")
        updater.update(
          "1.1.0",
          date: "2025-09-12",
          changes: {},
          fragment: :git,
          version_limit: 2
        )
        updater.write("CHANGELOG.md", retain_changelogs: false)

        # Verify the updates
        result = File.read("CHANGELOG.md")
        assert_match(/## \[1\.1\.0\] - 2025-09-12/, result)
        assert_match(/### Added\n\n- Export functionality/, result)
        assert_match(/### Fixed\n\n- Memory leak issue/, result)
      end
    end
  end

  def test_git_fragments_combine_with_explicit_changes
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup git repo with tagged version
        system("git init", out: File::NULL, err: File::NULL)
        system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
        system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

        File.write("test.txt", "initial")
        system("git add test.txt", out: File::NULL, err: File::NULL)
        system("git commit -m 'Initial'", out: File::NULL, err: File::NULL)
        system("git tag v1.0.0", out: File::NULL, err: File::NULL)

        # Add commit with trailer
        create_commit_with_trailer("From git", "Fixed: Bug from git trailer")

        # Create changelog
        File.write("CHANGELOG.md", <<~MD)
          # Changelog
          
          ## [1.0.0] - 2025-01-01
          ### Added
          - Initial release
        MD

        # Update with both explicit changes and git fragments
        updater = Reissue::ChangelogUpdater.new("CHANGELOG.md")
        updater.update(
          "1.1.0",
          date: "2025-09-12",
          changes: {
            "Added" => ["Manual entry from code"]
          },
          fragment: :git,
          version_limit: 2
        )
        updater.write("CHANGELOG.md", retain_changelogs: false)

        result = File.read("CHANGELOG.md")

        # Should have both manual and git entries
        assert_match(/### Added\n\n- Manual entry from code/, result)
        assert_match(/### Fixed\n\n- Bug from git trailer/, result)
      end
    end
  end

  def test_rake_task_configuration_with_git_fragments
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup git repo
        system("git init", out: File::NULL, err: File::NULL)
        system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
        system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

        # Create version file
        FileUtils.mkdir_p("lib/test_gem")
        File.write("lib/test_gem/version.rb", <<~RUBY)
          module TestGem
            VERSION = "0.1.0"
          end
        RUBY

        # Create Rakefile with git fragment configuration
        File.write("Rakefile", <<~RUBY)
          require "reissue/rake"
          
          Reissue::Task.create :reissue do |task|
            task.version_file = "lib/test_gem/version.rb"
            task.fragment = :git
            task.commit = false  # Don't commit in test
          end
        RUBY

        # Create initial changelog
        File.write("CHANGELOG.md", <<~MD)
          # Changelog

          ## [0.1.0] - 2025-01-01
          ### Added
          - Initial release
        MD

        # Commit and tag initial version
        system("git add .", out: File::NULL, err: File::NULL)
        system("git commit -m 'Initial version'", out: File::NULL, err: File::NULL)
        system("git tag v0.1.0", out: File::NULL, err: File::NULL)

        # Add commits with trailers
        create_commit_with_trailer("Feature", "Added: Amazing new feature")
        create_commit_with_trailer("Fix", "Fixed: Annoying bug")

        # Run the rake task
        `bundle exec rake reissue[patch] 2>&1`

        # Check that version was bumped
        version_content = File.read("lib/test_gem/version.rb")
        assert_match(/VERSION = "0\.1\.1"/, version_content)

        # Check that changelog was updated with git trailers
        changelog = File.read("CHANGELOG.md")
        assert_match(/## \[0\.1\.1\] - Unreleased/, changelog)
        assert_match(/### Added\n\n- Amazing new feature/, changelog)
        assert_match(/### Fixed\n\n- Annoying bug/, changelog)
      end
    end
  end

  private

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
end
