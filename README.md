# Reissue

Prepare the releases of your Ruby gems with ease.

When creating versioned software, it is important to keep track of the changes and the versions that are released.

After each release of a gem, you should immediatly bump the version with a new number and update the changelog with a place
to capture the information about new changes.

Reissue helps you to prepare the next version of your project by providing tools which will update version numbers and
update the changelog with a new version and a date.

Use Reissue to prepare your first commit going into the new version.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add reissue

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install reissue

## Usage

Build your own release with rake tasks provided by the gem. The following tasks are available:

- `rake reissue[segment]` - Prepare a new version for future work for the given version segment.
- `rake reissue:finalize` - Update the CHANGELOG.md file with a date for the latest version.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SOFware/reissue.
