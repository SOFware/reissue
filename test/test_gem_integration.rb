# frozen_string_literal: true

require "test_helper"
require "rake"
require "tmpdir"

class TestGemIntegration < Minitest::Test
  def setup
    @rake = Rake::Application.new
    Rake.application = @rake
  end

  def teardown
    Rake.application.clear
  end

  def test_gem_module_adds_checksums_to_updated_paths
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo("0.1.0")

        File.write("Rakefile", <<~RUBY)
          require "rake"

          task :build
          task :release

          require "reissue/gem"

          Reissue::Task.create :reissue do |task|
            task.version_file = "version.rb"
          end
        RUBY
        load "Rakefile"

        task_instance = ObjectSpace.each_object(Reissue::Task).find { |t|
          t.version_file == "version.rb" && t.updated_paths.include?("checksums")
        }
        refute_nil task_instance
        assert_includes task_instance.updated_paths, "checksums"
      end
    end
  end

  def test_gem_module_checksums_included_in_finalize_commit
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo("0.1.0")

        # Create a checksums file with initial content
        File.write("checksums", "SHA256 initial")
        system("git add checksums", out: File::NULL, err: File::NULL)
        system("git commit -m 'Add checksums'", out: File::NULL, err: File::NULL)

        # Modify checksums (simulating bundle install regenerating it)
        File.write("checksums", "SHA256 updated")

        File.write("Rakefile", <<~RUBY)
          require "rake"

          task :build
          task :release

          require "reissue/gem"

          Reissue::Task.create :reissue do |task|
            task.version_file = "version.rb"
            task.commit_finalize = true
          end

          Rake::Task["reissue:push"].clear
          task "reissue:push" do
          end
        RUBY
        load "Rakefile"

        capture_io do
          Rake::Task["reissue:finalize"].invoke("2025-01-01")
        end

        # Verify checksums was included in the finalize commit
        diff_output = `git show --name-only --format="" HEAD`.strip
        assert_includes diff_output, "checksums"
      end
    end
  end

  private

  def setup_git_repo(version)
    system("git init", out: File::NULL, err: File::NULL)
    system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
    system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

    File.write("version.rb", "VERSION = \"#{version}\"")
    File.write("CHANGELOG.md", <<~CHANGELOG)
      # Changelog

      ## [#{version}] - Unreleased

      ### Added

      - Initial release
    CHANGELOG

    system("git add .", out: File::NULL, err: File::NULL)
    system("git commit -m 'Initial commit'", out: File::NULL, err: File::NULL)
    system("git branch -M main", out: File::NULL, err: File::NULL)
  end
end
