# frozen_string_literal: true

require "test_helper"
require "rake"
require "stringio"
require "tmpdir"

class TestRakeChangelogFileOption < Minitest::Test
  def setup
    @original_stdout = $stdout
    @rake = Rake::Application.new
    Rake.application = @rake
  end

  def teardown
    $stdout = @original_stdout
    Rake.application.clear
  end

  def test_reissue_task_uses_configured_changelog_file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")

        # Create a lowercase changelog file (case-sensitive filesystem issue)
        File.write("changelog.md", <<~CHANGELOG)
          # Changelog

          ## [1.2.3] - Unreleased

          ### Added

          - Existing feature
        CHANGELOG

        create_rakefile_with_changelog("changelog.md")
        load "Rakefile"

        output = StringIO.new
        $stdout = output

        Rake::Task["reissue"].invoke("patch")

        # Verify the custom changelog file was updated with the new version
        changelog_content = File.read("changelog.md")

        assert_match(/\[1\.2\.4\]/, changelog_content,
          "Custom changelog file should be updated with new version")
        assert_match(/Existing feature/, changelog_content,
          "Custom changelog file should preserve existing content")
      end
    end
  end

  def test_reissue_task_with_custom_changelog_path
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("2.0.0")

        # Create changelog in a subdirectory
        FileUtils.mkdir_p("docs")
        File.write("docs/HISTORY.md", <<~CHANGELOG)
          # History

          ## [2.0.0] - Unreleased

          ### Changed

          - Major update
        CHANGELOG

        create_rakefile_with_changelog("docs/HISTORY.md")
        load "Rakefile"

        output = StringIO.new
        $stdout = output

        Rake::Task["reissue"].invoke("minor")

        # Verify the custom path changelog was updated
        changelog_content = File.read("docs/HISTORY.md")

        assert_match(/\[2\.1\.0\]/, changelog_content,
          "Changelog at custom path should be updated")
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
    system("git tag v#{version}", out: File::NULL, err: File::NULL)
  end

  def create_rakefile_with_changelog(changelog_path)
    File.write("Rakefile", <<~RUBY)
      require "reissue/rake"

      Reissue::Task.create :reissue do |task|
        task.version_file = "version.rb"
        task.changelog_file = "#{changelog_path}"
        task.commit = false
      end
    RUBY
  end
end
