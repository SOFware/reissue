# Simple example of using git trailers with Reissue
#
# Add this to your Rakefile:

require "reissue/gem"  # or "reissue/rake" for non-gems

Reissue::Task.create do |task|
  task.version_file = "lib/my_gem/version.rb"
  task.fragment = :git  # Enable git trailers
end

# That's it! Now when you commit, add trailers:
#
# git commit -m "Fix critical bug
#
# Fixed: User authentication not working
# Added: Better error messages"
#
# When you run `rake release`, these trailers will be
# automatically added to your CHANGELOG.md
