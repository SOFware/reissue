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

| Input | Default | Description |
|-------|---------|-------------|
| `git_user_email` | `github-actions[bot]@users.noreply.github.com` | Email for git commits |
| `git_user_name` | `github-actions[bot]` | Name for git commits |
| `dry_run` | `false` | Test workflow without publishing to RubyGems |

The workflow auto-detects the repository's default branch.

## Outputs

| Output | Description |
|--------|-------------|
| `version` | The version that was released |

Example using the output:
```yaml
jobs:
  release:
    uses: SOFware/reissue/.github/workflows/shared-ruby-gem-release.yml@main

  notify:
    needs: release
    runs-on: ubuntu-latest
    steps:
      - run: echo "Released version ${{ needs.release.outputs.version }}"
```

## What It Does

1. Records starting branch
2. Finalizes changelog using `rake build:checksum`
3. Detects if reissue created a new branch during finalization
4. Extracts version from built gem
5. Commits finalization changes if any
6. Publishes to RubyGems.org via Trusted Publishing (runs `rake release` which triggers reissue's version bump)
7. Detects if reissue created a new branch during version bump
8. Either creates a PR (if on new branch) or pushes directly to default branch

## Rake Task Configuration

The workflow handles two scenarios based on your Rakefile config:

**Option A: Rake creates branches (recommended for review workflow)**
```ruby
Reissue::Task.create do |task|
  task.version_file = "lib/my_gem/version.rb"
  task.commit = true
  task.push_reissue = :branch  # Rake creates branch, workflow creates PR
end
```

**Option B: Workflow handles commits (for CI-disabled commits)**
```ruby
Reissue::Task.create do |task|
  task.version_file = "lib/my_gem/version.rb"
  task.commit = !ENV["GITHUB_ACTIONS"]  # Disabled in CI
  task.push_reissue = false
end
```
The workflow detects uncommitted changes and commits/pushes them directly.

## Prerequisites

1. **Reissue configured in Rakefile** with `version_file` set
2. **RubyGems Trusted Publishing** configured for the repository
3. **GitHub Actions permissions** for contents and pull-requests
