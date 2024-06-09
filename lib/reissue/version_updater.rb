module Reissue
  module_function def greeks
    %w[alpha beta gamma delta epsilon zeta eta theta kappa lambda mu nu xi omicron pi rho sigma tau upsilon phi chi psi omega]
  end

  # Provides versioning functionality for the application.
  module Versioning
    # Provides versioning functionality for the application.
    refine ::Gem::Version do
      # Redoes the version based on the specified segment_name.
      #
      # @param segment_name [Symbol] The segment_name to redo the version.
      #   Possible values are :major, :minor, or any other symbol.
      # @return [Gem::Version] The updated version.
      def redo(segment_name)
        ::Gem::Version.create({
          major: [segments[0].next, 0, 0],
          minor: [segments[0], segments[1].next, 0],
          patch: [segments[0], segments[1], segments[2].next]
        }.fetch(segment_name.to_sym).join("."))
      end
    end

    refine ::String do
      def greek?
        Reissue.greeks.include?(downcase)
      end

      def next
        if greek?
          Reissue.greeks[Reissue.greeks.index(downcase).next]
        else
          succ
        end
      end
    end
  end

  class VersionUpdater
    using Versioning

    # Initializes a new instance of the VersionUpdater class.
    #
    # @param version_file [String] The path to the version file.
    def initialize(version_file)
      @version_file = version_file
      @original_version = nil
      @new_version = nil
      @updated_body = ""
    end

    # Updates the version segment and writes the updated version to the file.
    #
    # This allows you to read from one file and write to another.
    #
    # @param segment [Symbol] The segment to update (:major, :minor, or :patch).
    # @param version_file [String] The version_file to the version file (optional, defaults to @version_file).
    # @return [String] The updated version string.
    def call(segment, version_file: @version_file)
      update(segment)
      write(version_file)
      @new_version
    end

    # Updates the specified segment of the version string.
    #
    # @param segment [Symbol] The segment to update (:major, :minor, or :patch).
    # @return [String] The updated version string.
    def update(segment)
      version_file = File.read(@version_file)
      @updated_body = version_file.gsub(version_regex) do |string|
        @original_version = ::Gem::Version.new(string)
        @new_version = ::Gem::Version.new(string).redo(segment).to_s
      end
      @new_version
    end

    # Regular expression pattern for matching the version string.
    #
    # @return [Regexp] The version regex pattern.
    def version_regex = /(?<major>[a-zA-Z\d]+)\.(?<minor>[a-zA-Z\d]+)\.(?<patch>[a-zA-Z\d]+)/

    # Writes the updated version to the specified file.
    #
    # @param version_file [String] The version_file to the version file (optional, defaults to @version_file).
    def write(version_file = @version_file)
      File.write(version_file, @updated_body)
    end
  end
end
