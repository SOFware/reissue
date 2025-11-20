# Shared Release Workflow

Reissue hosts the shared release workflow for Ruby gems.

## Usage in Reissue

```yaml
jobs:
  release:
    uses: ./.github/workflows/shared-ruby-gem-release.yml
    with:
      gem_name: reissue
      module_name: Reissue
      git_user_email: 'gems@sofwarellc.com'
      git_user_name: 'SOFware'
```

## Usage in Other Gems

```yaml
jobs:
  release:
    uses: SOFware/reissue/.github/workflows/shared-ruby-gem-release.yml@main
    with:
      gem_name: your-gem-name
      module_name: YourModuleName
      # Optional: customize git commit author
      git_user_email: 'your-email@example.com'
      git_user_name: 'YourOrgName'
```

## Required Inputs

- `gem_name` - Gem name (e.g., `reissue`, `discharger`)
- `module_name` - Ruby module name for version constant (e.g., `Reissue`, `Discharger`)

## Optional Inputs

- `git_user_email` - Email for git commits (default: `github-actions[bot]@users.noreply.github.com`)
- `git_user_name` - Name for git commits (default: `github-actions[bot]`)

## Ruby Version

Ruby version is auto-detected from `.ruby-version`, `.tool-versions`, or `Gemfile`.

## What It Does

1. Finalizes changelog using `rake build:checksum`
2. Commits finalization if needed
3. Publishes to RubyGems.org via Trusted Publishing
4. Creates PR with post-release version bump

## Prerequisites

Each gem needs:
- Reissue configured in Rakefile
- RubyGems Trusted Publishing configured
- GitHub Actions permissions enabled
