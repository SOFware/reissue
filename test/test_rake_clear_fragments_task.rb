# frozen_string_literal: true

require "test_helper"
require "rake"
require "tmpdir"

class TestRakeClearFragmentsTask < Minitest::Test
  def setup
    @rake = Rake::Application.new
    Rake.application = @rake
  end

  def teardown
    Rake.application.clear
  end

  def test_clear_fragments_skips_when_fragment_is_git_symbol
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        system("git init", out: File::NULL, err: File::NULL)
        system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
        system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

        File.write("test.txt", "initial")
        system("git add test.txt", out: File::NULL, err: File::NULL)
        system("git commit -m 'Initial'", out: File::NULL, err: File::NULL)

        File.write("Rakefile", <<~RUBY)
          require "reissue/rake"

          Reissue::Task.create :reissue do |task|
            task.version_file = "version.rb"
            task.fragment = :git
            task.clear_fragments = true
          end
        RUBY

        File.write("version.rb", 'VERSION = "1.0.0"')

        load "Rakefile"

        # Should not raise an error when fragment is :git
        # Previously this would fail trying to run "git add :git"
        Rake::Task["reissue:clear_fragments"].invoke
        assert true
      end
    end
  end

  def test_clear_fragments_runs_for_directory_fragments
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        system("git init", out: File::NULL, err: File::NULL)
        system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
        system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

        File.write("test.txt", "initial")
        system("git add test.txt", out: File::NULL, err: File::NULL)
        system("git commit -m 'Initial'", out: File::NULL, err: File::NULL)

        # Create fragment directory with a fragment file (pattern: *.*.md)
        Dir.mkdir("changelog_fragments")
        File.write("changelog_fragments/1.added.md", "New feature")

        File.write("Rakefile", <<~RUBY)
          require "reissue/rake"

          Reissue::Task.create :reissue do |task|
            task.version_file = "version.rb"
            task.fragment = "changelog_fragments"
            task.clear_fragments = true
            task.commit_clear_fragments = false
          end
        RUBY

        File.write("version.rb", 'VERSION = "1.0.0"')

        load "Rakefile"

        # Verify fragment file exists before
        assert File.exist?("changelog_fragments/1.added.md")

        Rake::Task["reissue:clear_fragments"].invoke

        # Verify fragment file was cleared
        refute File.exist?("changelog_fragments/1.added.md")
      end
    end
  end
end
