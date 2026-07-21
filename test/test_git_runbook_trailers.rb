# frozen_string_literal: true

require "test_helper"
require "reissue/fragment_handler"
require "tmpdir"

class TestGitRunbookTrailers < Minitest::Test
  def test_extracts_runbook_trailers_with_sha
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo
        create_commit("Add cleanup task\n\nRunbook: Run `rake data:cleanup`")

        handler = Reissue::FragmentHandler.for(:git)
        entries = handler.read_runbook_entries

        assert_equal 1, entries.length
        assert_match(/\ARun `rake data:cleanup` \(\h{7,}\)\z/, entries.first)
      end
    end
  end

  def test_trailer_key_is_case_insensitive
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo
        create_commit("One\n\nrunbook: lowercase step")
        create_commit("Two\n\nRUNBOOK: uppercase step")

        handler = Reissue::FragmentHandler.for(:git)
        entries = handler.read_runbook_entries

        assert_equal 2, entries.length
        assert_match(/\Alowercase step/, entries[0])
        assert_match(/\Auppercase step/, entries[1])
      end
    end
  end

  def test_joins_continuation_lines
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo
        create_commit("Add step\n\nRunbook: Run the cleanup\n  and verify the results")

        handler = Reissue::FragmentHandler.for(:git)
        entries = handler.read_runbook_entries

        assert_equal 1, entries.length
        assert_match(/\ARun the cleanup and verify the results/, entries.first)
      end
    end
  end

  def test_only_reads_commits_since_last_tag
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo
        create_commit("Old\n\nRunbook: old step")
        create_tag("v1.0.0")
        create_commit("New\n\nRunbook: new step")

        handler = Reissue::FragmentHandler.for(:git)
        entries = handler.read_runbook_entries

        assert_equal 1, entries.length
        assert_match(/\Anew step/, entries.first)
      end
    end
  end

  def test_returns_empty_array_without_trailers
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo
        create_commit("No trailers here")

        handler = Reissue::FragmentHandler.for(:git)

        assert_empty handler.read_runbook_entries
      end
    end
  end

  def test_runbook_trailers_are_not_changelog_entries
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        setup_git_repo
        create_commit("Mixed\n\nFixed: a bug\nRunbook: a manual step")

        handler = Reissue::FragmentHandler.for(:git)
        changelog_entries = handler.read

        assert changelog_entries.key?("Fixed")
        refute changelog_entries.key?("Runbook")
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
    sleep(0.1)
    system("git tag -a #{tag_name} -m 'Release #{tag_name}'", out: File::NULL, err: File::NULL)
  end

  def create_commit(message)
    filename = "file_#{Time.now.to_f}.txt"
    File.write(filename, "content")
    system("git add #{filename}", out: File::NULL, err: File::NULL)
    system("git", "commit", "-m", message, out: File::NULL, err: File::NULL)
  end
end
