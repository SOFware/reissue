# frozen_string_literal: true

require "test_helper"
require "rake"
require "stringio"
require "tmpdir"

class TestRakePreviewTask < Minitest::Test
  def setup
    @original_stdout = $stdout
    @rake = Rake::Application.new
    Rake.application = @rake
  end

  def teardown
    $stdout = @original_stdout
    Rake.application.clear
  end

  def test_preview_with_git_trailers
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup git repo with tagged version
        system("git init", out: File::NULL, err: File::NULL)
        system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
        system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

        # Create initial commit and tag
        File.write("test.txt", "initial")
        system("git add test.txt", out: File::NULL, err: File::NULL)
        system("git commit -m 'Initial'", out: File::NULL, err: File::NULL)
        system("git tag v1.0.0", out: File::NULL, err: File::NULL)

        # Add commits with trailers
        create_commit_with_trailer("Feature", "Added: New feature")
        create_commit_with_trailer("Fix", "Fixed: Important bug")

        # Create Rakefile with git fragment configuration
        File.write("Rakefile", <<~RUBY)
          require "reissue/rake"
          
          Reissue::Task.create :reissue do |task|
            task.version_file = "version.rb"
            task.fragment = :git
          end
        RUBY

        # Create version file
        File.write("version.rb", 'VERSION = "1.0.0"')

        # Capture output
        output = StringIO.new
        $stdout = output

        # Load and run the preview task
        load "Rakefile"
        Rake::Task["reissue:preview"].invoke

        result = output.string

        # Verify output
        assert_match(/### Added/, result)
        assert_match(/- New feature/, result)
        assert_match(/### Fixed/, result)
        assert_match(/- Important bug/, result)
        assert_match(/Total: 2 entries across 2 sections/, result)
      end
    end
  end

  def test_preview_with_no_fragments_configured
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Create Rakefile without fragment configuration
        File.write("Rakefile", <<~RUBY)
          require "reissue/rake"
          
          Reissue::Task.create :reissue do |task|
            task.version_file = "version.rb"
          end
        RUBY

        # Create version file
        File.write("version.rb", 'VERSION = "1.0.0"')

        # Capture output
        output = StringIO.new
        $stdout = output

        # Load and run the preview task
        load "Rakefile"
        Rake::Task["reissue:preview"].invoke

        result = output.string

        # Verify output
        assert_match(/Fragment handling is not configured/, result)
        assert_match(/Set task.fragment to a directory path or :git/, result)
      end
    end
  end

  def test_preview_with_empty_git_trailers
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup git repo with no trailers
        system("git init", out: File::NULL, err: File::NULL)
        system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
        system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

        File.write("test.txt", "initial")
        system("git add test.txt", out: File::NULL, err: File::NULL)
        system("git commit -m 'Initial'", out: File::NULL, err: File::NULL)
        system("git tag v1.0.0", out: File::NULL, err: File::NULL)

        # Add commit without trailers
        File.write("test2.txt", "content")
        system("git add test2.txt", out: File::NULL, err: File::NULL)
        system("git commit -m 'Regular commit'", out: File::NULL, err: File::NULL)

        # Create Rakefile with git fragment configuration
        File.write("Rakefile", <<~RUBY)
          require "reissue/rake"
          
          Reissue::Task.create :reissue do |task|
            task.version_file = "version.rb"
            task.fragment = :git
          end
        RUBY

        File.write("version.rb", 'VERSION = "1.0.0"')

        # Capture output
        output = StringIO.new
        $stdout = output

        load "Rakefile"
        Rake::Task["reissue:preview"].invoke

        result = output.string

        # Verify output
        assert_match(/No changelog entries found/, result)
        assert_match(/No git trailers found since last version tag/, result)
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
