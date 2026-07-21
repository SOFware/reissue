require_relative "rake"
require "rubygems"

module Reissue
  module Gem
    def initialize(...)
      super
      @updated_paths << "checksums"
    end

    # Keep bundler's gemspec in step with the bump.
    #
    # Bundler loads the gemspec when bundler/gem_tasks is required, well before
    # reissue:bump rewrites the version file. `gem build` shells out and re-reads
    # the file, so the gem itself carries the bumped version, but the release tag
    # and bundler's confirmation messages read the copy held in memory. Without
    # this they name the version from before the bump, and the release publishes
    # one version under another version's tag.
    def apply_version_bump(updater, bump)
      new_version = super
      sync_bundler_gemspec_version(new_version)
      new_version
    end

    # @param new_version [String] the version the bump landed on
    def sync_bundler_gemspec_version(new_version)
      return unless defined?(Bundler::GemHelper)

      helper = Bundler::GemHelper.instance
      return unless helper.respond_to?(:gemspec) && helper.gemspec

      helper.gemspec.version = ::Gem::Version.new(new_version)
    end
  end
end
Reissue::Task.prepend Reissue::Gem

# Run rake reissue:bump and reissue:finalize _before_ the build task as prerequisites.
Rake::Task[:build].enhance(["reissue:bump", "reissue:finalize"])

# Run the reissue task after the release task.
Rake::Task["release"].enhance do
  Rake::Task["reissue"].invoke
end
