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
| `version` | The version that was released. Empty on a dry run, which does not build a gem. |

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

1. Records the starting branch
2. Runs `rake build:checksum release`, a single rake invocation that:
   - runs `reissue:bump` and `reissue:finalize`, which are prerequisites of `build`
   - builds the gem into `pkg/` and writes its SHA512 into `checksums/`
   - tags the release and publishes to RubyGems.org via Trusted Publishing
   - runs reissue's post-release version bump
3. Reads the released version back out of the gem that was actually built
4. Waits for the gem to appear in the RubyGems index
5. Detects whether reissue moved onto a new branch
6. Commits anything reissue left behind (including the new checksum) if it did not
7. Pushes the branch and opens a PR for the post-release version bump

`build:checksum` and `release` both depend on `build`, and rake runs a task at most
once per process, so naming both on one command line builds the gem a single time
and guarantees the checksum is written before anything is published.

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
