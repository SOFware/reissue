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

          assert_equal({"Fixed" => ["Widget now flip-flops doo-dads"]}, result)
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

          expected = {
            "Added" => ["New turbo mode configuration"],
            "Changed" => ["Refactored flux capacitor"],
            "Fixed" => ["Memory leak in quantum processor"]
          }
          assert_equal expected, result
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

          expected = {
            "Fixed" => ["First bug squashed"],
            "Added" => ["Cool new feature"]
          }
          assert_equal expected, result
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

          expected = {
            "Fixed" => ["Lowercase section name"],
            "Added" => ["Uppercase section name"],
            "Changed" => ["Normal case section name"]
          }
          assert_equal expected, result
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

          assert_equal({"Fixed" => ["Valid trailer"]}, result)
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
          expected = {
            "Fixed" => ["Important bug fix"],
            "Added" => ["New feature after release"]
          }
          assert_equal expected, result
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
          assert_equal({"Fixed" => ["Bug after v2"]}, result)
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

          assert_equal({"Security" => ["Fixed SQL injection vulnerability"]}, result)
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

          expected = {
            "Deprecated" => ["Old API will be removed in v3.0"],
            "Removed" => ["Legacy authentication system"]
          }
          assert_equal expected, result
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

          expected = {
            "Fixed" => ["Bug one", "Bug two", "Bug three"]
          }
          assert_equal expected, result
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
