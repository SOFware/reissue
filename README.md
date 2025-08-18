# Reissue

Automate your Ruby gem releases with proper versioning and changelog management.

Keep your version numbers and changelogs consistent and up-to-date with minimal effort.

## Bottom Line Up Front

When releasing gems, you typically run `rake build:checksum` to build the gem and generate the checksum, 
then `rake release` to push the `.gem` file to [rubygems.org](https://rubygems.org).

With Reissue, the process remains the same, but you get automatic version bumping and changelog management included.

Also supports non-gem Ruby projects.

## How It Works

The workflow:

1. Start with a version number (e.g., 0.1.0) for your unreleased project.
2. Make commits and develop features.
3. Release the version, finalizing the changelog with the release date.
4. Reissue automatically bumps to the next version (e.g., 0.1.1) and prepares the changelog for future changes.

After each release, Reissue handles the version bump and changelog updates, so you're immediately ready for the next development cycle.

## Installation

Add to your application's Gemfile:

    $ bundle add reissue

Or install directly:

    $ gem install reissue

## Usage

### Gem Projects

Add to your Rakefile:

```ruby
require "reissue/gem"

Reissue::Task.create :reissue do |task|
  # Required: Path to your version file
  task.version_file = "lib/my_gem/version.rb"
end
```

This integrates with standard gem tasks:
- `rake build` - Now finalizes the changelog before building
- `rake release` - Automatically bumps version after release

Additional tasks (usually run automatically):
- `rake reissue[segment]` - Bump version (major, minor, patch)
- `rake reissue:finalize[date]` - Add release date to changelog
- `rake reissue:reformat[version_limit]` - Clean up changelog formatting
- `rake reissue:clear_fragments` - Clear changelog fragments after release

### Non-Gem Projects

For non-gem Ruby projects, add to your Rakefile:

```ruby
require "reissue/rake"

Reissue::Task.create :reissue do |task|
  task.version_file = "path/to/version.rb"
end
```

Then use the rake tasks to manage your releases.

### Configuration Options

All available configuration options:

```ruby
Reissue::Task.create :reissue do |task|
  # Required: The file to update with the new version number
  task.version_file = "lib/my_gem/version.rb"
  
  # Optional: The name of the task. Defaults to "reissue"
  task.name = "reissue"
  
  # Optional: The description of the main task
  task.description = "Prepare the next version of the gem"
  
  # Optional: The changelog file to update. Defaults to "CHANGELOG.md"
  task.changelog_file = "CHANGELOG.md"
  
  # Optional: The number of versions to maintain in the changelog. Defaults to 2
  task.version_limit = 5
  
  # Optional: Whether to commit the changes automatically. Defaults to true
  task.commit = true
  
  # Optional: Whether to commit the results of the finalize task. Defaults to true
  task.commit_finalize = true
  
  # Optional: Whether to push the changes automatically. Defaults to false
  # Options: false, true (push working branch), :branch (create and push new branch)
  task.push_finalize = :branch
  
  # Optional: Directory containing fragment files for changelog entries. Defaults to nil (disabled)
  task.fragment_directory = "changelog_fragments"
  
  # Optional: Whether to clear fragment files after releasing. Defaults to false
  # When true, fragments are cleared after a release
  task.clear_fragments = true
  
  # Optional: Retain changelog files for previous versions. Defaults to false
  # Options: true (retain in "changelogs" directory), "path/to/archive", or a Proc
  task.retain_changelogs = true
  # task.retain_changelogs = "path/to/archive"
  # task.retain_changelogs = ->(version, content) { # custom logic }
  
  # Optional: Custom version formatting logic. Receives a Gem::Version object and segment
  task.version_redo_proc = ->(version, segment) do
    # your special versioning logic
    version.bump
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt.

## Releasing This Gem

1. Run `rake build:checksum` to build the gem and generate checksums
2. Run `rake release` to push to [rubygems.org](https://rubygems.org)
3. The version will automatically bump and the changelog will be updated
4. Push the changes to the repository

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SOFware/reissue.
