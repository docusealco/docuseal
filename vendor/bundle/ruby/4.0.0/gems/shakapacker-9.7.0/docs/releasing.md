# Releasing Shakapacker

This guide is for Shakapacker maintainers who need to publish a new release.

## Prerequisites

1. **Install required tools:**

   ```bash
   bundle install              # Installs gem-release
   yarn global add release-it  # Installs release-it for npm publishing
   gh --version                # Required for automatic GitHub release creation
   ```

2. **Ensure you have publishing access:**
   - npm: You must be a collaborator on the [shakapacker npm package](https://www.npmjs.com/package/shakapacker)
   - RubyGems: You must be an owner of the [shakapacker gem](https://rubygems.org/gems/shakapacker)

3. **Enable 2FA on both platforms:**
   - npm: 2FA is required for publishing
   - RubyGems: 2FA is required for publishing

4. **Authenticate GitHub CLI:**
   - Run `gh auth login` and ensure your account/token has write access to this repository
   - Required for automatic GitHub release creation after publishing

## Release Process

### 1. Update the Changelog

**Always update CHANGELOG.md before running the release task.** The release task reads the version from CHANGELOG.md and automatically creates a GitHub release from the changelog section.

1. Ensure all desired changes are merged to `main` branch
2. Run `/update-changelog release` (or `rc` or `beta` for prereleases) to:
   - Find merged PRs missing from the changelog
   - Add changelog entries under the appropriate category headings
   - Auto-compute the next version based on changes (breaking → major, features → minor, fixes → patch)
   - Stamp the version header (e.g., `## [v9.6.0] - March 7, 2026`)
3. Review the changelog entries and verify the computed version
4. Commit and push CHANGELOG.md

If you forget this step, the release task will print a warning and the GitHub release will need to be created manually afterward using `sync_github_release`.

### 2. Run the Release Task

The simplest way to release is with no arguments — the task reads the version from CHANGELOG.md:

```bash
# Recommended: reads version from CHANGELOG.md (requires step 1)
bundle exec rake release

# For a specific version (overrides CHANGELOG.md detection)
bundle exec rake "release[9.1.0]"

# For a beta release (note: use period, not dash)
bundle exec rake "release[9.2.0.beta.1]"  # Creates npm package 9.2.0-beta.1

# For a release candidate
bundle exec rake "release[9.6.0.rc.0]"

# Dry run to test without publishing
bundle exec rake "release[9.1.0,true]"

# Skip interactive confirmations (for scripted maintainer runs)
AUTO_CONFIRM=true bundle exec rake release

# Override version policy checks (monotonic + changelog/bump consistency)
RELEASE_VERSION_POLICY_OVERRIDE=true bundle exec rake "release[9.1.0]"
bundle exec rake "release[9.1.0,false,true]"
```

When called with no arguments, `release`:

1. Reads the first versioned header from CHANGELOG.md (e.g., `## [v9.6.0]`)
2. Compares it to the current gem version
3. If the changelog version is newer, prompts for confirmation and uses it
4. If no new version is found, falls back to a patch bump

Dry runs use a temporary git worktree so version bumps and installs do not modify your current checkout.
Dry runs now also print explicit "skipping confirmation" messages and the would-run GitHub release command.

`release` validates release-version policy before publishing:

- Target version must be greater than the latest tagged release.
- If the versioned target changelog section exists (`## [vX.Y.Z...]`; not `UNRELEASED`), it maps to expected bump type:
  - Breaking changes => major bump
  - Added/New Features/Features/Enhancements => minor bump
  - Fixed/Fixes/Bug Fixes/Security/Improved/Deprecated => patch bump
  - Other headings => no inferred bump level (consistency check is skipped)

Use override only when needed:

- `RELEASE_VERSION_POLICY_OVERRIDE=true`
- Or task arg override (`release[..., ..., true]`)

### 3. What the Release Task Does

The `release` task automatically:

1. **Validates release prerequisites**:
   - Verifies npm authentication
   - Warns if CHANGELOG.md section is missing for the target version
2. **Pulls latest changes** from the repository
3. **Bumps version numbers** in:
   - `lib/shakapacker/version.rb` (Ruby gem version)
   - `package.json` (npm package version - converted from Ruby format)
4. **Publishes to npm:**
   - Prompts for npm OTP (2FA code)
   - Creates git tag
   - Pushes to GitHub
5. **Publishes to RubyGems:**
   - Prompts for RubyGems OTP (2FA code)
6. **Updates spec/dummy lockfiles:**
   - Runs `bundle install` to update `Gemfile.lock`
   - Runs `yarn install` to refresh the Yarn-managed dummy app lockfile
   - Runs `npm install` to keep `package-lock.json` in sync for npm compatibility/testing
7. **Commits and pushes lockfile changes** automatically
8. **Creates GitHub release** from CHANGELOG.md (if the matching section exists)

### 4. Version Format

**Important:** Use Ruby gem version format (no dashes):

- ✅ Correct: `9.1.0`, `9.2.0.beta.1`, `9.0.0.rc.2`
- ❌ Wrong: `9.1.0-beta.1`, `9.0.0-rc.2`

The task automatically converts Ruby gem format to npm semver format:

- Ruby: `9.2.0.beta.1` → npm: `9.2.0-beta.1`
- Ruby: `9.0.0.rc.2` → npm: `9.0.0-rc.2`

**CHANGELOG.md headers** use npm semver format (with dashes):

- `## [v9.6.0-rc.1]` — correct (matches git tag format)
- `## [v9.6.0.rc.1]` — wrong (RubyGems format, will not be found by release tasks)

**Examples:**

```bash
# Regular release
bundle exec rake "release[9.1.0]"  # Gem: 9.1.0, npm: 9.1.0

# Beta release
bundle exec rake "release[9.2.0.beta.1]"  # Gem: 9.2.0.beta.1, npm: 9.2.0-beta.1

# Release candidate
bundle exec rake "release[10.0.0.rc.1]"  # Gem: 10.0.0.rc.1, npm: 10.0.0-rc.1

# Prerelease: use /update-changelog rc first, then release reads it
bundle exec rake release  # reads v10.0.0-rc.0 from CHANGELOG.md
```

### 5. During the Release

If you are running non-interactively, set `AUTO_CONFIRM=true` to skip confirmation prompts.

1. When prompted for **npm OTP**, enter your 2FA code from your authenticator app
2. Accept defaults for release-it options
3. When prompted for **RubyGems OTP**, enter your 2FA code
4. If using `release` with no version, confirm the version detected from CHANGELOG.md (or the computed patch version)
5. The script will automatically commit and push lockfile updates
6. The script will automatically create a GitHub release (if CHANGELOG.md section exists)

### 6. After Release

1. Verify the release on:
   - [npm](https://www.npmjs.com/package/shakapacker)
   - [RubyGems](https://rubygems.org/gems/shakapacker)
   - [GitHub releases](https://github.com/shakacode/shakapacker/releases)

2. Check that the lockfile commit was pushed:

   ```bash
   git log --oneline -5
   # Should see "Update spec/dummy lockfiles after release"
   ```

3. Announce the release (if appropriate):
   - Post in relevant Slack/Discord channels
   - Tweet about major releases
   - Update documentation if needed

### Syncing GitHub Releases Manually

If the automatic GitHub release creation was skipped (e.g., CHANGELOG.md section was missing during release), you can create it manually after updating the changelog:

1. Update `CHANGELOG.md` with the published version section
   - For prerelease entries, use npm semver header format with dashes, for example `## [v9.6.0-rc.1]`
2. Commit and push `CHANGELOG.md`
3. Run:

```bash
# Stable
bundle exec rake "sync_github_release[9.6.0]"

# Prerelease
bundle exec rake "sync_github_release[9.6.0.rc.1]"
```

`sync_github_release` reads release notes from the matching `CHANGELOG.md` section and creates/updates the GitHub release for the corresponding tag.

## Troubleshooting

### Uncommitted Changes After Release

If you see uncommitted changes to lockfiles after a release, this means:

1. The release was successful but the lockfile commit step may have failed
2. **Solution:** Manually commit these files:
   ```bash
   git add spec/dummy/Gemfile.lock spec/dummy/package-lock.json spec/dummy/yarn.lock
   git commit -m 'Update spec/dummy lockfiles after release'
   git push
   ```

### Failed npm or RubyGems Publish

If publishing fails partway through:

1. Check which step failed (npm or RubyGems)
2. If npm failed: Fix the issue and manually run `npm publish`
3. If RubyGems failed: Fix the issue and manually run `gem release`
4. Then manually update and commit spec/dummy lockfiles

### GitHub Release Sync Fails

If package publishing succeeds but GitHub release creation fails:

1. Fix GitHub auth (`gh auth login`) or permissions
2. Ensure `CHANGELOG.md` has matching header `## [vX.Y.Z...]` (npm format for prereleases)
3. Rerun only:

   ```bash
   bundle exec rake "sync_github_release[<gem_version>]"
   ```

### Wrong Version Format

If you accidentally use npm format (with dashes):

1. The gem will be created with an invalid version
2. **Solution:** Don't push the changes, reset your branch:
   ```bash
   git reset --hard HEAD
   ```
3. Re-run with correct Ruby gem format

## Manual Release Steps

If you need to release manually (not recommended):

1. **Bump version:**

   ```bash
   gem bump --version 9.1.0
   bundle install
   ```

2. **Publish to npm:**

   ```bash
   release-it 9.1.0 --npm.publish
   ```

3. **Publish to RubyGems:**

   ```bash
   gem release
   ```

4. **Update lockfiles:**
   ```bash
   cd spec/dummy
   bundle install
   npm install
   cd ../..
   git add spec/dummy/Gemfile.lock spec/dummy/package-lock.json spec/dummy/yarn.lock
   git commit -m 'Update spec/dummy lockfiles after release'
   git push
   ```

## Questions?

If you encounter issues not covered here, please:

1. Check the [CONTRIBUTING.md](../CONTRIBUTING.md) guide
2. Ask in the maintainers channel
3. Update this documentation for future releases
