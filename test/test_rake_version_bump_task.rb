# frozen_string_literal: true

require "test_helper"
require "rake"
require "stringio"
require "tmpdir"

class TestRakeVersionBumpTask < Minitest::Test
  def setup
    @original_stdout = $stdout
    @rake = Rake::Application.new
    Rake.application = @rake
  end

  def teardown
    $stdout = @original_stdout
    Rake.application.clear
  end

  def test_bump_with_major_trailer
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")

        # Add commit with major version trailer
        create_commit_with_trailer("Breaking change", "Version: major")

        create_rakefile
        load "Rakefile"

        # Capture output
        output = StringIO.new
        $stdout = output

        Rake::Task["reissue:bump"].invoke

        result = output.string
        version_content = File.read("version.rb")

        # Verify version was bumped to 2.0.0
        assert_match(/VERSION = "2.0.0"/, version_content)
        assert_match(/Version bumped \(major\) to 2\.0\.0/, result)
      end
    end
  end

  def test_bump_with_minor_trailer
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")

        # Add commit with minor version trailer
        create_commit_with_trailer("New feature", "Version: minor")

        create_rakefile
        load "Rakefile"

        output = StringIO.new
        $stdout = output

        Rake::Task["reissue:bump"].invoke

        result = output.string
        version_content = File.read("version.rb")

        # Verify version was bumped to 1.3.0
        assert_match(/VERSION = "1.3.0"/, version_content)
        assert_match(/Version bumped \(minor\) to 1\.3\.0/, result)
      end
    end
  end

  def test_bump_with_patch_trailer
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")

        # Add commit with patch version trailer
        create_commit_with_trailer("Bug fix", "Version: patch")

        create_rakefile
        load "Rakefile"

        output = StringIO.new
        $stdout = output

        Rake::Task["reissue:bump"].invoke

        result = output.string
        version_content = File.read("version.rb")

        # Verify version was bumped to 1.2.4
        assert_match(/VERSION = "1.2.4"/, version_content)
        assert_match(/Version bumped \(patch\) to 1\.2\.4/, result)
      end
    end
  end

  def test_bump_with_no_version_trailers
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")

        # Add commit without version trailer
        create_commit_with_trailer("Regular fix", "Fixed: Some bug")

        create_rakefile
        load "Rakefile"

        output = StringIO.new
        $stdout = output

        Rake::Task["reissue:bump"].invoke

        result = output.string
        version_content = File.read("version.rb")

        # Verify version was NOT bumped
        assert_match(/VERSION = "1.2.3"/, version_content)
        refute_match(/Version bumped/, result)
      end
    end
  end

  def test_version_bump_precedence_major_over_minor
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")

        # Add commits with different version trailers
        create_commit_with_trailer("Minor change", "Version: minor")
        create_commit_with_trailer("Major change", "Version: major")

        create_rakefile
        load "Rakefile"

        output = StringIO.new
        $stdout = output

        Rake::Task["reissue:bump"].invoke

        version_content = File.read("version.rb")

        # Verify major version wins (2.0.0, not 1.3.0)
        assert_match(/VERSION = "2.0.0"/, version_content)
      end
    end
  end

  def test_version_bump_idempotency_skips_when_already_bumped
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")

        # Add commit with major version trailer
        create_commit_with_trailer("Breaking change", "Version: major")

        create_rakefile
        load "Rakefile"

        # First invocation - should bump
        output1 = StringIO.new
        $stdout = output1
        Rake::Task["reissue:bump"].invoke
        result1 = output1.string

        assert_match(/Version bumped \(major\) to 2\.0\.0/, result1)

        # Reset rake tasks for second invocation
        Rake.application.clear
        @rake = Rake::Application.new
        Rake.application = @rake
        load "Rakefile"

        # Second invocation - should skip
        output2 = StringIO.new
        $stdout = output2
        Rake::Task["reissue:bump"].invoke
        result2 = output2.string

        version_content = File.read("version.rb")

        # Verify version is still 2.0.0 and not bumped again
        assert_match(/VERSION = "2.0.0"/, version_content)
        assert_match(/Version already bumped.*1\.2\.3.*2\.0\.0.*skipping/, result2)
      end
    end
  end

  def test_version_bump_with_multiple_major_trailers_only_bumps_once
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo_with_version("1.2.3")

        # Add multiple commits with major version trailer
        create_commit_with_trailer("First major", "Version: major")
        create_commit_with_trailer("Second major", "Version: major")
        create_commit_with_trailer("Third major", "Version: major")

        create_rakefile
        load "Rakefile"

        output = StringIO.new
        $stdout = output

        Rake::Task["reissue:bump"].invoke

        version_content = File.read("version.rb")

        # Verify version is 2.0.0 (not 4.0.0)
        assert_match(/VERSION = "2.0.0"/, version_content)
      end
    end
  end

  def test_version_bump_works_when_no_tags_exist
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Setup git repo WITHOUT a tag
        system("git init", out: File::NULL, err: File::NULL)
        system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
        system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

        # Create initial version file
        File.write("version.rb", 'VERSION = "0.1.0"')
        system("git add version.rb", out: File::NULL, err: File::NULL)
        system("git commit -m 'Initial version'", out: File::NULL, err: File::NULL)

        # Add commit with major version trailer
        create_commit_with_trailer("Breaking change", "Version: major")

        create_rakefile
        load "Rakefile"

        output = StringIO.new
        $stdout = output

        Rake::Task["reissue:bump"].invoke

        version_content = File.read("version.rb")

        # Verify version was bumped even without tags
        assert_match(/VERSION = "1.0.0"/, version_content)
      end
    end
  end

  private

  def setup_git_repo_with_version(version)
    system("git init", out: File::NULL, err: File::NULL)
    system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
    system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

    # Create initial version file and tag
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
