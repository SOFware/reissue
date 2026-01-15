# frozen_string_literal: true

require "test_helper"
require "reissue/fragment_handler"
require "tmpdir"

class TestGitFragmentHandlerTagPattern < Minitest::Test
  def test_find_last_tag_with_default_pattern
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo
        create_tag("v1.0.0")
        create_commit("second commit")
        create_tag("v1.1.0")

        handler = Reissue::FragmentHandler.for(:git)
        assert_equal "v1.1.0", handler.last_tag
      end
    end
  end

  def test_find_last_tag_with_custom_pattern
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo
        # Create tags for main app and sub-gem with commits between
        create_tag("v2025.12.1")
        create_commit("commit after A")
        create_tag("qualified-v0.3.5")
        create_commit("commit after qualified")
        create_tag("v2025.12.2")

        # Without pattern, should find main app tag (most recent v* tag)
        handler_no_pattern = Reissue::FragmentHandler.for(:git)
        assert_equal "v2025.12.2", handler_no_pattern.last_tag

        # With pattern, should find sub-gem tag
        handler_with_pattern = Reissue::FragmentHandler.for(:git, tag_pattern: /^qualified-v(\d+\.\d+\.\d+.*)$/)
        assert_equal "qualified-v0.3.5", handler_with_pattern.last_tag
      end
    end
  end

  def test_last_tag_version_extracts_from_pattern
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo
        create_tag("myapp-v1.2.3")

        handler = Reissue::FragmentHandler.for(:git, tag_pattern: /^myapp-v(\d+\.\d+\.\d+.*)$/)
        assert_equal Gem::Version.new("1.2.3"), handler.last_tag_version
      end
    end
  end

  def test_last_tag_version_with_default_pattern
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo
        create_tag("v2.0.0")

        handler = Reissue::FragmentHandler.for(:git)
        assert_equal Gem::Version.new("2.0.0"), handler.last_tag_version
      end
    end
  end

  def test_commits_since_last_tag_with_pattern
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo

        # Create main app tag
        create_tag("v2025.12.1")

        # Create commits
        create_commit("Main app commit\n\nAdded: Main app feature")

        # Create sub-gem tag
        create_tag("qualified-v0.3.5")

        # Create more commits after sub-gem tag
        create_commit("Sub-gem commit\n\nFixed: Sub-gem bug")

        # Handler with pattern should only see commits since qualified-v0.3.5
        handler = Reissue::FragmentHandler.for(:git, tag_pattern: /^qualified-v(\d+\.\d+\.\d+.*)$/)
        entries = handler.read

        assert entries.key?("Fixed"), "Should have Fixed section"
        assert_equal 1, entries["Fixed"].length
        assert_match(/Sub-gem bug/, entries["Fixed"].first)

        # Should NOT include the main app feature
        refute entries.key?("Added"), "Should not have Added section from commits before sub-gem tag"
      end
    end
  end

  def test_pattern_with_prerelease_versions
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo
        create_tag("v1.0.0")
        create_commit("second commit")
        create_tag("v1.1.0.pre1")
        create_commit("third commit")
        create_tag("v1.1.0")

        handler = Reissue::FragmentHandler.for(:git)
        # v1.1.0 should be higher than v1.1.0.pre1
        assert_equal "v1.1.0", handler.last_tag
      end
    end
  end

  private

  def setup_git_repo
    system("git init", out: File::NULL, err: File::NULL)
    system("git config user.name 'Test'", out: File::NULL, err: File::NULL)
    system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)

    File.write("test.txt", "initial")
    system("git add test.txt", out: File::NULL, err: File::NULL)
    system("git commit -m 'Initial commit'", out: File::NULL, err: File::NULL)
  end

  def create_tag(tag_name)
    # Use annotated tags (-a) so they have their own creation timestamp
    # Add small sleep to ensure different timestamps when creating multiple tags
    sleep(0.1)
    system("git tag -a #{tag_name} -m 'Release #{tag_name}'", out: File::NULL, err: File::NULL)
  end

  def create_commit(message)
    filename = "file_#{Time.now.to_f}.txt"
    File.write(filename, "content")
    system("git add #{filename}", out: File::NULL, err: File::NULL)

    if message.include?("\n")
      Tempfile.create("commit_msg") do |f|
        f.write(message)
        f.flush
        system("git commit -F #{f.path}", out: File::NULL, err: File::NULL)
      end
    else
      system("git commit -m '#{message}'", out: File::NULL, err: File::NULL)
    end
  end
end
