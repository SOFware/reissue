# Reissue

Prepare the releases of your Ruby gems with ease.

When creating versioned software, it is important to keep track of the changes and the versions that are released.

After each release of a gem, you should immediatly bump the version with a new number and update the changelog with a place
to capture the information about new changes.

Reissue helps you to prepare the next version of your project by providing tools which will update version numbers and
update the changelog with a new version and a date.

Use Reissue to prepare your first commit going into the new version.

Standard procedure for releasing projects with Reissue:

1. Create a version with some number like 0.1.0.
2. Add commits to the project. These will be associated with the version 0.1.0.
3. When you are releasing your project, finalize it by running
  `rake reissue:finalize` to update the Unreleased version in your changelog.
4. Bump the version to 0.1.1 with `rake reissue[patch]` and commit those changes.
   Future commits will be associated with the version 0.1.1 until your next release.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add reissue

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install reissue

## Usage

If you are working with a gem, you can add the following to the Rakefile:

```ruby
require "reissue/gem"

Reissue::Task.create :reissue do |task|
  # Required: The file to update with the new version number.
  task.version_file = "lib/my_gem/version.rb"
end
```

This will add the following rake tasks:

- `rake reissue[segment]` - Prepare a new version for future work for the given
  version segment.
- `rake reissue:finalize[date]` - Update the CHANGELOG.md file with a date for
  the latest version.
- `rake reissue:reformat[version_limit]` - Reformat the CHANGELOG.md file and
  optionally limit the number of versions to maintain.

This will also update the `build` task from rubygems to first run
`reissue:finalize` and then build the gem, ensuring that your changelog is
up-to-date before the gem is built.

It updates the `release` task from rubygems to run `reissue` after the gem is
pushed to rubygems.

Build your own release with rake tasks provided by the gem.

Add the following to the Rakefile:

```ruby
require "reissue/rake"

Reissue::Task.create :reissue do |task|
  # Required: The file to update with the new version number.
  task.version_file = "path/to/version.rb"
end
```

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

  # Optional: The number of versions to maintain in the changelog.
  task.version_limit = 5

  # Optional: A Proc to format the version number. Receives a Gem::Version object, and segment.
  task.format_version = ->(version, segment) do
    # your special versioning logic
  end

  # Optional: The file to update with the new version number.
  task.changelog_file = "path/to/CHANGELOG.md"

  # Optional: Whether to commit the changes automatically. Defaults to true.
  task.commit = false

  # Optional: Whether or not to commit the results of the finalize task. Defaults to true.
  task.commit_finalize = false
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SOFware/reissue.
