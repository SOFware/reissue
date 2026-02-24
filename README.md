# Reissue

Automate your Ruby gem releases with proper versioning and changelog management.

Keep your version numbers and changelogs consistent and up-to-date with minimal effort.

## Bottom Line Up Front

When releasing gems, you typically run `rake build:checksum` to build the gem and generate checksums,
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
- `rake reissue:preview` - Preview changelog entries from fragments or git trailers
- `rake reissue:clear_fragments` - Clear changelog fragments after release

### Hoe Projects

If you use [Hoe](https://github.com/seattlerb/hoe) for project management:

```ruby
Hoe.plugin :reissue

Hoe.spec "my_gem" do
  developer "Jane Doe", "jane@example.com"

  self.reissue_version_file = "lib/my_gem/version.rb"
  self.reissue_fragment = :git
  self.reissue_push_finalize = :branch
end
```

This hooks into Hoe's release lifecycle:
- `prerelease` - Runs `reissue:bump` and `reissue:finalize` before release
- `postrelease` - Runs `reissue` to bump version for the next development cycle

All configuration options are available as `reissue_`-prefixed attributes (e.g., `reissue_version_file`, `reissue_changelog_file`, `reissue_changelog_sections`). The version file defaults to `lib/#{name}/version.rb`.

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
  
  # Optional: Configure fragment handling for changelog entries. Defaults to nil (disabled)
  # Options:
  #   - nil or false: Fragments disabled
  #   - String path: Use directory-based fragments (e.g., "changelog_fragments")
  #   - :git: Extract changelog entries from git commit trailers
  task.fragment = "changelog_fragments"
  # task.fragment = :git  # Use git trailers for changelog entries
  
  # Optional: Whether to clear fragment files after releasing. Defaults to false
  # When true, fragments are cleared after a release (only applies when using directory fragments)
  # Note: Has no effect when using :git fragments
  task.clear_fragments = true

  # Optional: Ordered list of valid changelog sections. Controls validation and display order.
  # Defaults to: %w[Added Changed Deprecated Removed Fixed Security]
  # Custom sections can be added; setting is idempotent (duplicates removed, names capitalized)
  task.changelog_sections = %w[Major Added Changed Deprecated Removed Fixed Security]

  # Optional: Tag pattern for matching version tags. Defaults to /^v(\d+\.\d+\.\d+.*)$/
  # Must include a capture group for the version number.
  # Only applies when using :git fragments
  # Examples:
  #   /^v(\d+\.\d+\.\d+.*)$/ matches "v1.2.3" (default)
  #   /^myapp-v(\d+\.\d+\.\d+.*)$/ matches "myapp-v1.2.3"
  task.tag_pattern = /^myapp-v(\d+\.\d+\.\d+.*)$/

  # Deprecated: Use `fragment` instead of `fragment_directory`
  # task.fragment_directory = "changelog_fragments"  # DEPRECATED: Use task.fragment instead

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

## Tracking Release Dates

Reissue can automatically manage a `RELEASE_DATE` constant in your version file alongside `VERSION`. This is completely optional — if no `RELEASE_DATE` is present, nothing changes.

### Opting In

Add a `RELEASE_DATE` constant to your version file:

```ruby
module MyGem
  VERSION = "0.1.0"
  RELEASE_DATE = "Unreleased"
end
```

### What Happens Automatically

- **On finalize** (`rake build` / `rake reissue:finalize`): `RELEASE_DATE` is set to the actual release date (e.g., `"2024-06-15"`)
- **On bump** (`rake reissue` / post-release): `RELEASE_DATE` is reset to `"Unreleased"`

No configuration is needed — Reissue detects the constant and updates it automatically.

## Using Git Trailers for Changelog Entries

Reissue can extract changelog entries directly from git commit messages using trailers. This keeps your changelog data close to the code changes.

### Configuration

```ruby
Reissue::Task.create :reissue do |task|
  task.version_file = "lib/my_gem/version.rb"
  task.fragment = :git  # Enable git trailer extraction
end
```

### Adding Trailers to Commits

Use changelog section names as trailer keys in your commit messages:

```bash
git commit -m "Implement user authentication

Added: User login and logout functionality
Added: Password reset via email
Fixed: Session timeout not working correctly
Security: Rate limiting on login attempts"
```

### Supported Sections

Git trailers use the standard [Keep a Changelog](http://keepachangelog.com/) sections by default:
- `Added:` for new features
- `Changed:` for changes in existing functionality
- `Deprecated:` for soon-to-be removed features
- `Removed:` for now removed features
- `Fixed:` for any bug fixes
- `Security:` for vulnerability fixes

You can customize the valid sections with `changelog_sections`. This controls both which trailer names are recognized and the order sections appear in the changelog:

```ruby
task.changelog_sections = %w[Major Added Changed Deprecated Removed Fixed Security]
```

### How It Works

1. When you run `rake reissue`, it finds all commits since the last version tag
2. Extracts trailers matching changelog sections from commit messages
3. Adds them to the appropriate sections in your CHANGELOG.md
4. Trailers are case-insensitive (e.g., `fixed:`, `Fixed:`, `FIXED:` all work)

### Example Workflow

```bash
# Make your changes
git add .
git commit -m "Add export functionality

Added: CSV export for user data
Added: PDF report generation
Fixed: Date formatting in exports"

# Release (trailers are automatically extracted)
rake build:checksum
rake release
```

The changelog will be updated with the entries from your commit trailers.

### Version Bumping with Git Trailers

When using git fragments (`task.fragment = :git`), you can also control version bumping through commit trailers. Add a `Version:` trailer to your commit messages to specify the type of version bump.

#### Configuration

The version bump feature is automatically enabled when using git fragments:

```ruby
Reissue::Task.create :reissue do |task|
  task.version_file = "lib/my_gem/version.rb"
  task.fragment = :git  # Enables both changelog and version trailers
end
```

#### Version Trailer Syntax

Add a `Version:` trailer to specify the bump type:

```bash
git commit -m "Add breaking API changes

Added: New REST API endpoints
Changed: Authentication now requires API keys
Version: major"
```

Supported version bump types:
- `Version: major` - Increments major version (1.2.3 → 2.0.0)
- `Version: minor` - Increments minor version (1.2.3 → 1.3.0)
- `Version: patch` - Increments patch version (1.2.3 → 1.2.4)

#### Precedence Rules

When multiple commits contain `Version:` trailers, the highest precedence bump is applied:

**Precedence:** major > minor > patch

Examples:
- Commits with `Version: patch` and `Version: minor` → minor bump applied
- Commits with `Version: minor` and `Version: major` → major bump applied
- Multiple `Version: major` trailers → only one major bump applied

#### Idempotency

The version bump is idempotent - running `rake build` multiple times before releasing will only bump the version once:

1. **First build:** Version bumped from 1.2.3 → 2.0.0 (based on `Version: major` trailer)
2. **Second build:** Version bump skipped (already at 2.0.0)
3. **Third build:** Version bump skipped (already at 2.0.0)
4. **After release:** Patch bump to 2.0.1 (standard post-release behavior)

This is achieved by comparing the current version in your version file with the last git tag version. If they differ, the version was already bumped and the bump is skipped.

#### Example Workflow

```bash
# Make changes with a major version bump
git commit -m "Redesign authentication system

Changed: Complete overhaul of auth architecture
Removed: Support for legacy OAuth 1.0
Added: OAuth 2.0 and JWT support
Version: major"

# Build (version bumps from 1.2.3 → 2.0.0)
rake build:checksum

# Build again (version bump skipped - already at 2.0.0)
rake build:checksum

# Release (creates v2.0.0 tag and bumps to 2.0.1)
rake release
```

#### Case Insensitivity

Version trailers are case-insensitive:
- `Version: major`, `version: major`, `VERSION: MAJOR` all work

#### When to Use Version Trailers

- **Breaking changes:** Use `Version: major` for incompatible API changes
- **New features:** Use `Version: minor` for backwards-compatible new functionality
- **Bug fixes:** Use `Version: patch` for backwards-compatible bug fixes (or omit - patch is the default post-release bump)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt.

## Automated Releases with GitHub Actions

### For This Gem (Reissue)

Use the GitHub Actions workflow for streamlined releases:

1. Go to Actions tab in GitHub
2. Select "Release gem to RubyGems.org" workflow
3. Click "Run workflow"
4. The workflow will:
   - Finalize the changelog with the release date
   - Build and publish the gem to RubyGems.org using Trusted Publishing
   - Create a PR with the next version bump
5. Merge the version bump PR to continue development

### For Other Gems Using Reissue

Reissue provides a shared release workflow that any gem can use. See [SHARED_WORKFLOW_README.md](.github/workflows/SHARED_WORKFLOW_README.md) for setup instructions and configuration options.

### Manual Release

For local releases (requires RubyGems API credentials configured locally, not recommended):

1. Run `rake build:checksum` to build the gem and generate checksums
2. Run `rake release` to push to [rubygems.org](https://rubygems.org)
3. The version will automatically bump and the changelog will be updated
4. Push the changes to the repository

The GitHub Actions workflow with Trusted Publishing is the recommended approach.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SOFware/reissue.
