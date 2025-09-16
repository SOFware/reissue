require "test_helper"
require "reissue/fragment_handler"

class TestFragmentHandler < Minitest::Test
  def test_base_class_read_raises_not_implemented_error
    handler = Reissue::FragmentHandler.new
    assert_raises(NotImplementedError) do
      handler.read
    end
  end

  def test_base_class_clear_raises_not_implemented_error
    handler = Reissue::FragmentHandler.new
    assert_raises(NotImplementedError) do
      handler.clear
    end
  end

  def test_for_method_with_nil_returns_null_handler
    handler = Reissue::FragmentHandler.for(nil)
    assert_instance_of Reissue::NullFragmentHandler, handler
  end

  def test_for_method_with_string_returns_directory_handler
    handler = Reissue::FragmentHandler.for("changelog_fragments")
    assert_instance_of Reissue::DirectoryFragmentHandler, handler
  end

  def test_for_method_with_git_symbol_returns_git_handler
    handler = Reissue::FragmentHandler.for(:git)
    assert_instance_of Reissue::FragmentHandler::GitFragmentHandler, handler
  end

  def test_for_method_with_invalid_type_raises_argument_error
    error = assert_raises(ArgumentError) do
      Reissue::FragmentHandler.for(123)
    end
    assert_match(/Invalid fragment option: 123/, error.message)
  end

  def test_for_method_with_unsupported_symbol_raises_argument_error
    error = assert_raises(ArgumentError) do
      Reissue::FragmentHandler.for(:unsupported)
    end
    assert_match(/Invalid fragment option: :unsupported/, error.message)
  end
end

class TestNullFragmentHandler < Minitest::Test
  def setup
    # Ensure the handler is loaded via the factory method
    @handler = Reissue::FragmentHandler.for(nil)
  end

  def test_read_returns_empty_hash
    assert_equal({}, @handler.read)
  end

  def test_clear_does_nothing
    # Should not raise any errors
    assert_nil @handler.clear
  end
end
