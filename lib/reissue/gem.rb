require_relative "rake"
require "rubygems"

module Reissue
  module Gem
    def initialize(...)
      super
      @updated_paths << "checksums"
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
