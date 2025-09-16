# frozen_string_literal: true

module Reissue
  # Handler for when no fragment source is configured
  class NullFragmentHandler < FragmentHandler
    # Read fragments (returns empty hash since no source is configured)
    #
    # @return [Hash] An empty hash
    def read
      {}
    end

    # Clear fragments (no-op since no source is configured)
    #
    # @return [nil]
    def clear
      nil
    end
  end
end
