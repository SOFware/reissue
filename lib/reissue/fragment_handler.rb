# frozen_string_literal: true

module Reissue
  # Base class for handling fragment reading from various sources
  class FragmentHandler
    # Read fragments from the configured source
    #
    # @return [Hash] A hash of changelog entries organized by category
    # @raise [NotImplementedError] Must be implemented by subclasses
    def read
      raise NotImplementedError, "Subclasses must implement #read"
    end

    # Clear fragments from the configured source
    #
    # @raise [NotImplementedError] Must be implemented by subclasses
    def clear
      raise NotImplementedError, "Subclasses must implement #clear"
    end

    # Factory method to create the appropriate handler for the given option
    #
    # @param fragment_option [nil, String, Symbol] The fragment configuration
    # @param valid_sections [Array<String>, nil] List of valid section names (for directory handler)
    # @return [FragmentHandler] The appropriate handler instance
    # @raise [ArgumentError] If the option is not supported
    def self.for(fragment_option, valid_sections: nil)
      case fragment_option
      when nil
        require_relative "fragment_handler/null_fragment_handler"
        NullFragmentHandler.new
      when String
        require_relative "fragment_handler/directory_fragment_handler"
        options = {}
        options[:valid_sections] = valid_sections if valid_sections
        DirectoryFragmentHandler.new(fragment_option, **options)
      when :git
        require_relative "fragment_handler/git_fragment_handler"
        GitFragmentHandler.new
      else
        raise ArgumentError, "Invalid fragment option: #{fragment_option.inspect}"
      end
    end
  end
end
