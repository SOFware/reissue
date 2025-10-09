# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "tempfile"
require "reissue/fragment_handler"
require "reissue/fragment_handler/git_fragment_handler"

module Reissue
  class FragmentHandler
    class GitFragmentHandlerTest < Minitest::Test
      def setup
        @handler = nil
      end

      def teardown
        @handler = nil
      end

      def test_initialization
        handler = Reissue::FragmentHandler::GitFragmentHandler.new
        assert_instance_of Reissue::FragmentHandler::GitFragmentHandler, handler
      end

      def test_clear_returns_nil
        handler = Reissue::FragmentHandler::GitFragmentHandler.new
        assert_nil handler.clear
      end

      def test_read_returns_empty_hash_when_not_in_git_repo
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            handler = Reissue::FragmentHandler::GitFragmentHandler.new
            result = handler.read
            assert_equal({}, result)
          end
        end
      end

      def test_read_returns_empty_hash_when_no_commits
        with_test_git_repo do
          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read
          assert_equal({}, result)
        end
      end

      def test_read_parses_single_trailer
        with_test_git_repo do
          create_commit_with_message <<~MSG
            Fix important bug

            Fixed: Widget now flip-flops doo-dads
          MSG

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read

          assert_equal 1, result["Fixed"].length
          assert_match(/^Widget now flip-flops doo-dads \(\h{7}\)$/, result["Fixed"].first)
        end
      end

      def test_read_parses_multiple_trailers_in_one_commit
        with_test_git_repo do
          create_commit_with_message <<~MSG
            Major refactoring

            Added: New turbo mode configuration
            Changed: Refactored flux capacitor
            Fixed: Memory leak in quantum processor
          MSG

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read

          assert_equal 1, result["Added"].length
          assert_equal 1, result["Changed"].length
          assert_equal 1, result["Fixed"].length
          assert_match(/^New turbo mode configuration \(\h{7}\)$/, result["Added"].first)
          assert_match(/^Refactored flux capacitor \(\h{7}\)$/, result["Changed"].first)
          assert_match(/^Memory leak in quantum processor \(\h{7}\)$/, result["Fixed"].first)
        end
      end

      def test_read_parses_trailers_from_multiple_commits
        with_test_git_repo do
          create_commit_with_message <<~MSG
            First fix

            Fixed: First bug squashed
          MSG

          create_commit_with_message <<~MSG
            Add feature

            Added: Cool new feature
          MSG

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read

          assert_equal 1, result["Fixed"].length
          assert_equal 1, result["Added"].length
          assert_match(/^First bug squashed \(\h{7}\)$/, result["Fixed"].first)
          assert_match(/^Cool new feature \(\h{7}\)$/, result["Added"].first)
        end
      end

      def test_read_handles_mixed_case_section_names
        with_test_git_repo do
          create_commit_with_message <<~MSG
            Various fixes

            fixed: Lowercase section name
            ADDED: Uppercase section name
            Changed: Normal case section name
          MSG

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read

          assert_equal 1, result["Fixed"].length
          assert_equal 1, result["Added"].length
          assert_equal 1, result["Changed"].length
          assert_match(/^Lowercase section name \(\h{7}\)$/, result["Fixed"].first)
          assert_match(/^Uppercase section name \(\h{7}\)$/, result["Added"].first)
          assert_match(/^Normal case section name \(\h{7}\)$/, result["Changed"].first)
        end
      end

      def test_read_ignores_invalid_trailers
        with_test_git_repo do
          create_commit_with_message <<~MSG
            Mixed content

            Fixed: Valid trailer
            NotASection: Invalid section name
            Missing colon trailer
            Random: Not a valid section
          MSG

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read

          assert_equal 1, result["Fixed"].length
          assert_match(/^Valid trailer \(\h{7}\)$/, result["Fixed"].first)
        end
      end

      def test_read_only_includes_commits_since_last_tag
        with_test_git_repo do
          # Create first commit and tag it
          create_commit_with_message <<~MSG
            Initial release

            Added: Initial functionality
          MSG
          system("git tag v1.0.0", out: File::NULL, err: File::NULL)

          # Create commits after tag
          create_commit_with_message <<~MSG
            Bug fix

            Fixed: Important bug fix
          MSG

          create_commit_with_message <<~MSG
            New feature

            Added: New feature after release
          MSG

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read

          # Should only include commits after the tag
          assert_equal 1, result["Fixed"].length
          assert_equal 1, result["Added"].length
          assert_match(/^Important bug fix \(\h{7}\)$/, result["Fixed"].first)
          assert_match(/^New feature after release \(\h{7}\)$/, result["Added"].first)
        end
      end

      def test_read_handles_multiple_tags
        with_test_git_repo do
          # Create first release
          create_commit_with_message "Initial commit"
          system("git tag v1.0.0", out: File::NULL, err: File::NULL)

          # Create second release
          create_commit_with_message <<~MSG
            Second release

            Added: Feature in v2
          MSG
          system("git tag v2.0.0", out: File::NULL, err: File::NULL)

          # Create commits after last tag
          create_commit_with_message <<~MSG
            Post-release fix

            Fixed: Bug after v2
          MSG

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read

          # Should only include commits after v2.0.0
          assert_equal 1, result["Fixed"].length
          assert_match(/^Bug after v2 \(\h{7}\)$/, result["Fixed"].first)
        end
      end

      def test_read_handles_commits_with_no_trailers
        with_test_git_repo do
          create_commit_with_message "Regular commit without trailers"
          create_commit_with_message "Another commit\n\nJust some description"

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read

          assert_equal({}, result)
        end
      end

      def test_read_handles_security_section
        with_test_git_repo do
          create_commit_with_message <<~MSG
            Security update

            Security: Fixed SQL injection vulnerability
          MSG

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read

          assert_equal 1, result["Security"].length
          assert_match(/^Fixed SQL injection vulnerability \(\h{7}\)$/, result["Security"].first)
        end
      end

      def test_read_handles_deprecated_and_removed_sections
        with_test_git_repo do
          create_commit_with_message <<~MSG
            Cleanup

            Deprecated: Old API will be removed in v3.0
            Removed: Legacy authentication system
          MSG

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read

          assert_equal 1, result["Deprecated"].length
          assert_equal 1, result["Removed"].length
          assert_match(/^Old API will be removed in v3\.0 \(\h{7}\)$/, result["Deprecated"].first)
          assert_match(/^Legacy authentication system \(\h{7}\)$/, result["Removed"].first)
        end
      end

      def test_read_aggregates_multiple_entries_per_section
        with_test_git_repo do
          create_commit_with_message <<~MSG
            First fix

            Fixed: Bug one
          MSG

          create_commit_with_message <<~MSG
            Second fix

            Fixed: Bug two
          MSG

          create_commit_with_message <<~MSG
            Third fix

            Fixed: Bug three
          MSG

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read

          assert_equal 3, result["Fixed"].length
          assert_match(/^Bug one \(\h{7}\)$/, result["Fixed"][0])
          assert_match(/^Bug two \(\h{7}\)$/, result["Fixed"][1])
          assert_match(/^Bug three \(\h{7}\)$/, result["Fixed"][2])
        end
      end

      def test_read_ignores_non_version_tags
        with_test_git_repo do
          # Create first commit with a non-version tag
          create_commit_with_message <<~MSG
            Old commit

            Added: Should not appear in results
          MSG
          system("git tag release-candidate", out: File::NULL, err: File::NULL)

          # Create another commit with a version tag
          create_commit_with_message <<~MSG
            Version release

            Added: Should not appear either
          MSG
          system("git tag v1.0.0", out: File::NULL, err: File::NULL)

          # Create commits after version tag
          create_commit_with_message <<~MSG
            New feature

            Fixed: Should appear in results
          MSG

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          result = handler.read

          # Should only include commits after v1.0.0, not after release-candidate
          assert_equal 1, result["Fixed"].length
          assert_match(/^Should appear in results \(\h{7}\)$/, result["Fixed"].first)
        end
      end

      def test_last_tag_returns_most_recent_version_tag
        with_test_git_repo do
          create_commit_with_message "First commit"
          system("git tag v1.0.0", out: File::NULL, err: File::NULL)

          sleep 0.1 # Ensure different timestamps

          create_commit_with_message "Second commit"
          system("git tag v1.1.0", out: File::NULL, err: File::NULL)

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          assert_equal "v1.1.0", handler.last_tag
        end
      end

      def test_last_tag_returns_nil_when_no_tags
        with_test_git_repo do
          create_commit_with_message "Commit without tag"

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          assert_nil handler.last_tag
        end
      end

      def test_last_tag_handles_multi_digit_version_numbers
        with_test_git_repo do
          create_commit_with_message "First commit"
          system("git tag v8.26.9", out: File::NULL, err: File::NULL)

          sleep 0.1 # Ensure different timestamps

          create_commit_with_message "Second commit"
          system("git tag v8.26.10", out: File::NULL, err: File::NULL)

          handler = Reissue::FragmentHandler::GitFragmentHandler.new
          # Should find v8.26.10 (not v8.26.9) despite 10 having more digits
          assert_equal "v8.26.10", handler.last_tag
        end
      end

      def test_read_uses_most_recently_created_tag_not_highest_version
        with_test_git_repo do
          # Create v9.0.0 first (higher version number)
          create_commit_with_message "Old high version"
          system("git tag v9.0.0", out: File::NULL, err: File::NULL)

          sleep 0.1 # Ensure different timestamps

          # Create v8.0.0 later (lower version number but more recent)
          create_commit_with_message <<~MSG
            Recent lower version

            Added: Should not appear
          MSG
          system("git tag v8.0.0", out: File::NULL, err: File::NULL)

          # Create commit after most recent tag
          create_commit_with_message <<~MSG
            New commit

            Fixed: Should appear
          MSG

          handler = Reissue::FragmentHandler::GitFragmentHandler.new

          # Should use v8.0.0 (most recently created) not v9.0.0 (highest version)
          assert_equal "v8.0.0", handler.last_tag

          result = handler.read
          assert_equal 1, result["Fixed"].length
          assert_match(/^Should appear \(\h{7}\)$/, result["Fixed"].first)
          assert_nil result["Added"] # Should not include commits before v8.0.0
        end
      end

      private

      def with_test_git_repo
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            system("git init", out: File::NULL, err: File::NULL)
            system("git config user.name 'Test User'", out: File::NULL, err: File::NULL)
            system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)
            yield
          end
        end
      end

      def create_commit_with_message(message)
        # Create or modify a file to have something to commit
        filename = "test_#{Time.now.to_f}.txt"
        File.write(filename, "test content")
        system("git add #{filename}", out: File::NULL, err: File::NULL)

        # Use a temp file for the commit message to handle multi-line messages properly
        Tempfile.create("commit_msg") do |f|
          f.write(message)
          f.flush
          system("git commit -F #{f.path}", out: File::NULL, err: File::NULL)
        end
      end
    end
  end
end
