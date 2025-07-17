# Reissue

Prepare the releases of your Ruby gems with ease.

When creating versioned software, it is important to keep track of the changes and the versions that are released.

## Bottome Line Up Front

When releasing gems you would typically do `rake build:checksum` to build the gem and generate the checksum.
Then you would run `rake release` to push the `.gem` file to [rubygems.org](https://rubygems.org) (or your gem server).

The process is still the same with Reissue, but you get changelog cleanup and version number management for free.

It also has support for non-gem projects.

## How it works

The approach is this:

1. Declare on what version you're working. For example all of my initial commits are associated with version 0.1.0 and the gem (or other project) is unreleased.
2. Add commits to the project.
3. Release the project, marking the end of the development on version 0.1.0.
4. Immediately bump the version with a new number (0.1.1 for example), update the changelog with a place to capture the information about new changes, and push the changes to the repository for continued development.

After each release of a gem Reissue takes care of immediately bumping the version with a new number and updating the changelog with a place to capture the information about new changes.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add reissue

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install reissue

## Usage

### Gem Projects

If you are working with a gem, you can add the following to the Rakefile:

```ruby
require "reissue/gem"

Reissue::Task.create :reissue do |task|
  # Required: The file to update with the new version number.
  task.version_file = "lib/my_gem/version.rb"
end
```

This will add the following rake tasks which you typically do not need to run manually:

- `rake reissue[segment]` - Prepare a new version for future work for the given
  version segment.
- `rake reissue:finalize[date]` - Update the CHANGELOG.md file with a date for
  the latest version.
- `rake reissue:reformat[version_limit]` - Reformat the CHANGELOG.md file and
  optionally limit the number of versions to maintain.
- `rake reissue:branch[branch-name]` - Create a new branch for the next version.
  Controlled by the `push_finalize` and `commit_finalize` options.
- `rake reissue:push` - Push the changes to the remote repository. Controlled
  by the `push_finalize` and `commit_finalize` options.
- `rake clear_fragments` - Clear changelog fragments after a release. Only runs
  if `fragment_directory` and `clear_fragments` are configured.

This will also update the `build` task from rubygems to first run
`reissue:finalize` and then build the gem, ensuring that your changelog is
up-to-date before the gem is built.

It updates the `release` task from rubygems to run `reissue` after the gem is
pushed to rubygems.

### Non-Gem Projects

Build your own release with rake tasks provided by the gem.

Add the following to the Rakefile:

```ruby
require "reissue/rake"

Reissue::Task.create :reissue do |task|
  # Required: The file to update with the new version number.
  task.version_file = "path/to/version.rb"
end
```

Use the provided rake tasks to prepare the next version of your project.

### Customizing the Rake Tasks

When creating your task, you have additional options to customize the behavior:

```ruby
require "reissue/rake"

Reissue::Task.create :your_name_and_namespace do |task|

  # Optional: The name of the task. Defaults to "reissue".
  task.name = "your_name_and_namespace"

  # Optional: The description of the main task.
  task.description = "Prepare the next version of the gem."

  # Required: The file to update with the new version number.
  task.version_file = "path/to/version.rb"

  # Optional: The number of versions to maintain in the changelog. Defaults to 2.
  task.version_limit = 5

  # Optional: A Proc to format the version number. Receives a Gem::Version object, and segment.
  task.version_redo_proc = ->(version, segment) do
    # your special versioning logic
  end

  # Optional: The file to update with the new version number. Defaults to "CHANGELOG.md".
  task.changelog_file = "path/to/CHANGELOG.md"

  # Optional: A Boolean, String, or Proc to retain the changelog files for the previous versions. Defaults to false.
  # Setting to true will retain the changelog files in the "changelogs" directory.
  # Setting to a String will use that path as the directory to retain the changelog files.
  # The Proc receives a version hash and the changelog content.
  task.retain_changelogs = ->(version, content) do
    # your special retention logic
  end
  # or task.retain_changelogs = "path/to/changelogs"
  # or task.retain_changelogs = true

  # Optional: Whether to commit the changes automatically. Defaults to true.
  task.commit = false

  # Optional: Whether or not to commit the results of the finalize task. Defaults to true.
  task.commit_finalize = false

  # Optional: Whether to push the changes automatically. Defaults to false.
  task.push_finalize = :branch # or false, or true to push the working branch

  # Optional: Directory containing fragment files for changelog entries. Defaults to nil (disabled).
  task.fragment_directory = "changelog_fragments"

  # Optional: Whether to clear fragment files after releasing. Defaults to false.
  # When true, fragments are cleared by the reissue:release task after a release.
  task.clear_fragments = true
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Releasing

Run `rake build:checksum` to build the gem and generate the checksum. This will also update the version number in the gemspec file.

Run `rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

This will leave a new commit with the version number incremented in the version file and the changelog updated with the new version.
Push the changes to the repository.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SOFware/reissue.
