# frozen_string_literal: true

require "test_helper"
require "reissue/rake"

class TestTaskFragmentOption < Minitest::Test
  def setup
    @task = Reissue::Task.new
  end

  def test_fragment_setter_accepts_nil
    @task.fragment = nil
    assert_nil @task.fragment
  end

  def test_fragment_setter_accepts_string_directory_path
    @task.fragment = "changelog_fragments"
    assert_equal "changelog_fragments", @task.fragment
  end

  def test_fragment_directory_setter_shows_deprecation_warning
    _, err = capture_io do
      @task.fragment_directory = "old_fragments"
    end

    assert_match(/DEPRECATION.*fragment_directory.*deprecated.*fragment/, err)
    assert_equal "old_fragments", @task.fragment
  end

  def test_fragment_directory_getter_shows_deprecation_warning
    @task.fragment = "test_fragments"

    _, err = capture_io do
      value = @task.fragment_directory
      assert_equal "test_fragments", value
    end

    assert_match(/DEPRECATION.*fragment_directory.*deprecated.*fragment/, err)
  end

  def test_fragment_directory_maintains_backward_compatibility
    capture_io do
      @task.fragment_directory = "legacy_fragments"
    end

    # Should still work despite deprecation
    assert_equal "legacy_fragments", @task.fragment

    # Should be accessible via both methods
    value = nil
    capture_io do
      value = @task.fragment_directory
    end
    assert_equal "legacy_fragments", value
  end

  def test_fragment_default_value_is_nil
    assert_nil @task.fragment
  end

  def test_deprecation_message_is_helpful
    _, err = capture_io do
      @task.fragment_directory = "test"
    end

    # Check for helpful migration guidance
    assert_match(/fragment_directory/, err)
    assert_match(/fragment/, err)
    assert_match(/deprecated/, err)
  end
end
