# Shared Release Workflow

Reissue provides a shared GitHub Actions workflow for releasing Ruby gems.

## Usage

```yaml
name: Release gem to RubyGems.org

on:
  workflow_dispatch:

jobs:
  release:
    uses: SOFware/reissue/.github/workflows/shared-ruby-gem-release.yml@main
    with:
      git_user_email: 'your-email@example.com'
      git_user_name: 'YourOrgName'
```

## Inputs

All inputs are optional:

- `git_user_email` - Email for git commits (default: `github-actions[bot]@users.noreply.github.com`)
- `git_user_name` - Name for git commits (default: `github-actions[bot]`)

## What It Does

1. Finalizes changelog using `rake build:checksum`
2. Commits finalization changes if any
3. Publishes to RubyGems.org via Trusted Publishing
4. Runs `rake reissue` to bump version for next cycle
5. Creates PR if the rake task created a new branch

## Prerequisites

Each gem needs:

1. **Reissue configured in Rakefile** with version file and branch settings:
   ```ruby
   Reissue::Task.create do |task|
     task.version_file = "lib/my_gem/version.rb"
     task.push_reissue = :branch  # Creates branch for version bump PR
   end
   ```

2. **RubyGems Trusted Publishing** configured for the repository

3. **GitHub Actions permissions** for contents and pull-requests
