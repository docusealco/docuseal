# Update Changelog

You are helping to add an entry to the CHANGELOG.md file for the Shakapacker project.

## Arguments

This command accepts an optional argument: `$ARGUMENTS`

- **No argument** (`/update-changelog`): Add entries to `[Unreleased]` without stamping a version header. Use this during development.
- **`release`** (`/update-changelog release`): Add entries and stamp a version header. Auto-compute the next version based on changes (breaking → major, added features → minor, fixes → patch). Then `rake release` (with no args) will pick up this version automatically.
- **`rc`** (`/update-changelog rc`): Same as `release`, but stamps an RC prerelease version (e.g., `v9.7.0-rc.0`). Auto-increments the RC index if prior RCs exist for the same base version.
- **`beta`** (`/update-changelog beta`): Same as `rc`, but stamps a beta prerelease version (e.g., `v9.7.0-beta.0`).
- **Explicit version** (`/update-changelog 9.7.0-rc.10` or `/update-changelog v9.7.0-rc.10`): Add entries and stamp the exact version provided. Skips auto-computation — use this when you already know the target version. The version string must use npm semver format with optional `-rc.N` or `-beta.N` suffix (e.g., `9.7.0-rc.10`, `9.7.0`). A `v` prefix is optional and will be added automatically if missing. If passed in RubyGems dot format (e.g., `9.7.0.rc.10` or `9.7.0.beta.2`), convert to npm semver dash format (`v9.7.0-rc.10` or `v9.7.0-beta.2`) for the changelog header.

## When to Use This

This command serves three use cases at different points in the release lifecycle:

**During development** — Add entries to `[Unreleased]` as PRs merge:

- Run `/update-changelog` to find merged PRs missing from the changelog
- Entries accumulate under `## [Unreleased]`

**Before a release** — Stamp a version header and prepare for release:

- Run `/update-changelog release` (or `rc` or `beta`) to add entries AND stamp the version header
- The version is auto-computed from changelog content (see "Auto-Computing the Next Version" below)
- Commit and push CHANGELOG.md
- Then run `rake release` (no args needed — it reads the version from CHANGELOG.md)
- The release task automatically creates a GitHub release from the changelog section

**After a release you forgot to update the changelog for** — Catch-up mode:

- The command can retroactively find commits between tags and add missing entries
- Ask the user whether to stamp a version header or add to `[Unreleased]`

### Why changelog comes BEFORE the release

- `release` automatically creates a GitHub release if a changelog section exists — no separate `sync_github_release` step needed
- The release task warns if no changelog section is found for the target version
- A premature version header (if release fails) is harmless — you'll release eventually
- A missing changelog after release means GitHub release must be created manually

## Auto-Computing the Next Version

When stamping a version header (`release`, `rc`, or `beta`), compute the next version as follows:

1. **Find the latest stable version tag** using semver sort:

   ```bash
   git tag -l 'v*' --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1
   ```

2. **Determine bump type from changelog content**:
   - If changes include `### Breaking Changes` or `### ⚠️ Breaking Changes` → **major** bump
   - If changes include `### Added` or `### New Features` → **minor** bump
   - If changes only include `### Fixed`, `### Security`, `### Improved`, `### Changed`, `### Deprecated` → **patch** bump

3. **Compute the version**:
   - For `release`: Apply the bump to the latest stable tag (e.g., `9.5.0` + minor → `9.6.0`)
   - For `rc`: Apply the bump, then find the next RC index based **only on git tags** (e.g., if `v9.6.0-rc.0` tag exists → `v9.6.0-rc.1`). **Do NOT use changelog headers** to determine the next index — a version header in the changelog is a draft that may not have been released yet. Only git tags represent shipped versions.
   - For `beta`: Same as RC but with beta suffix

4. **Verify**: Check that the computed version is newer than ALL existing tags (stable and prerelease). If not, ask the user what to do.

5. **Show the computed version to the user and ask for confirmation** before stamping the header. If the bump type is ambiguous (e.g., changes could reasonably be classified as patch vs minor, or the changelog headings don't clearly signal the bump level), explain your reasoning for the suggested bump and ask the user to confirm or override before proceeding.

## Critical Requirements

1. **User-visible changes only**: Only add changelog entries for user-visible changes:
   - New features
   - Bug fixes
   - Breaking changes
   - Deprecations
   - Performance improvements
   - Security fixes
   - Changes to public APIs or configuration options

2. **Do NOT add entries for**:
   - Linting fixes
   - Code formatting
   - Internal refactoring
   - Test updates
   - Documentation fixes (unless they fix incorrect docs about behavior)
   - CI/CD changes

## Formatting Requirements

### Entry Format

Each changelog entry MUST follow this exact format:

```markdown
- **Bold description of change**. [PR #123](https://github.com/shakacode/shakapacker/pull/123) by [username](https://github.com/username). Optional additional context or details.
```

**Important formatting rules**:

- Start with a dash and space: `- `
- Use **bold** for the main description
- End the bold description with a period before the link
- Always link to the PR: `[PR #123](https://github.com/shakacode/shakapacker/pull/123)` - **Note: Shakapacker uses `#` in PR links, unlike React on Rails**
- Always link to the author: `by [username](https://github.com/username)`
- End with a period after the author link
- Additional details can be added after the main entry, using proper indentation for multi-line entries

### Breaking Changes Format

For breaking changes, use this format:

```markdown
- **Breaking**: Description of the breaking change. See [Migration Guide](docs/vX_upgrade.md) for migration instructions. [PR #123](https://github.com/shakacode/shakapacker/pull/123) by [username](https://github.com/username).
```

### Category Organization

Entries should be organized under these section headings. The project uses both standard and custom headings:

**Standard headings** (from keepachangelog.com) - use these for most changes:

- `### Added` - New features
- `### Changed` - Changes to existing functionality
- `### Deprecated` - Deprecation notices
- `### Removed` - Removed features
- `### Fixed` - Bug fixes
- `### Security` - Security-related changes
- `### Improved` - Improvements to existing features

**Custom headings** (project-specific) - use sparingly when standard headings don't fit:

- `### ⚠️ Breaking Changes` - Breaking changes only (Shakapacker uses emoji in heading)
- `### API Improvements` - API changes and improvements
- `### Developer Experience` - Developer workflow improvements
- `### Performance` - Performance improvements

**Prefer standard headings.** Only use custom headings when the change needs more specific categorization.

**Only include section headings that have entries.**

### Version Header Format

**Stable releases**: `## [v9.6.0] - March 7, 2026`

**Prerelease versions** (RC and beta): Use npm semver format with dashes, NOT RubyGems dot format:

- Correct: `## [v9.6.0-rc.1]` (npm semver — this is what `sync_github_release` expects)
- Wrong: `## [v9.6.0.rc.1]` (RubyGems format — do NOT use this in CHANGELOG.md headers)

This matters because the release rake tasks convert between formats:

- Git tags use npm format: `v9.6.0-rc.1`
- Gem versions use RubyGems format: `9.6.0.rc.1`
- CHANGELOG.md headers must match git tag format: `## [v9.6.0-rc.1]`

### Version Management

After adding entries, use the rake task to manage version headers:

```bash
bundle exec rake update_changelog
```

This will:

- Add headers for the new version
- Update version diff links at the bottom of the file

### Version Links

After adding an entry to the `## [Unreleased]` section, ensure the version diff links at the bottom of the file are correct.

**IMPORTANT**: Compare links at the bottom MUST use the `v` prefix to match git tags (e.g., `.../compare/v9.2.0...v9.3.0`). This is consistent with Shakapacker's changelog headers which also include the `v` prefix (e.g., `## [v9.3.0]`).

The format at the bottom should be:

```markdown
[Unreleased]: https://github.com/shakacode/shakapacker/compare/v9.3.0...main
[v9.3.0]: https://github.com/shakacode/shakapacker/compare/v9.2.0...v9.3.0
```

When a new version is released:

1. Change `[Unreleased]` heading to `## [vX.Y.Z] - Month Day, Year`
2. Add a new `## [Unreleased]` section at the top
3. Update the `[Unreleased]` link to compare from the new version
4. Add a new version link for the released version

## Process

### For Regular Changelog Updates

#### Step 1: Fetch and read current state

- **CRITICAL**: Run `git fetch origin main --tags` to ensure you have the latest commits AND tags
- The workspace may be behind origin/main, causing you to miss recently merged PRs
- After fetching, use `origin/main` for all comparisons, NOT local `main` branch
- Read the current CHANGELOG.md to understand the existing structure

#### Step 2: Reconcile tags with changelog sections (DO THIS FIRST)

**This step catches missing version sections and is the #1 source of errors when skipped.**

1. Get the latest git tag: `git tag -l 'v*' --sort=-v:refname | head -5`
2. Get the most recent version header in CHANGELOG.md (the first `## [vVERSION]` after `## [Unreleased]`)
3. **Compare them.** If the latest git tag does NOT appear anywhere in the changelog version headers, there are tagged releases missing from the changelog. **Important**: Don't just compare against the _top_ changelog header — a version header may exist _above_ the latest tag if it was stamped as a draft before tagging. Check whether the tag's version appears in _any_ `## [vX.Y.Z]` header. For example:
   - Latest tag: `v9.6.0-rc.4`, and no `## [v9.6.0-rc.4]` header exists anywhere in CHANGELOG.md
   - **Result: `v9.6.0-rc.4` is missing and needs its own section**
   - But if `## [v9.7.0-rc.0]` is the top header (a draft, not yet tagged) and `## [v9.6.0-rc.4]` exists below it, then nothing is missing — the top header is simply a pre-release draft

4. For EACH missing tagged version (there may be multiple):
   a. Find commits in that tag vs the previous tag: `git log --oneline PREV_TAG..MISSING_TAG`
   b. Extract PR numbers and fetch details for user-visible changes
   c. Check which entries currently in `## [Unreleased]` actually belong to this tagged version (compare PR numbers against the commit list)
   d. **Create a new version section** immediately before the previous version section
   e. **Move** matching entries from Unreleased into the new section
   f. **Add** any new entries for PRs in that tag that aren't in the changelog at all
   g. **Update version diff links** at the bottom of the file

5. Get the tag date with: `git log -1 --format="%Y-%m-%d" TAG_NAME`

#### Step 3: Add new entries for post-tag commits

1. Run `git log --oneline LATEST_TAG..origin/main` to find commits after the latest tag (LATEST_TAG is the most recent git tag, i.e., the same one identified in Step 2)
2. **Extract ALL PR numbers** from commit messages: `git log --oneline LATEST_TAG..origin/main | grep -oE "#[0-9]+" | sort -u`
3. If Step 2 found no missing tagged versions, verify no tag is ahead of main: `git log --oneline origin/main..LATEST_TAG` should be empty. If not, entries in "Unreleased" may belong to that tagged version — Step 2 should have caught this, so re-check.
4. For each PR number, check if it's already in CHANGELOG.md: `grep "PR #XXX" CHANGELOG.md`
5. For PRs not yet in the changelog:
   - Get PR details: `gh pr view NUMBER --json title,body,author --repo shakacode/shakapacker`
   - **Never ask the user for PR details** — get them from git history or the GitHub API
   - Validate that the change is user-visible (per the criteria above). Skip CI, lint, refactoring, test-only changes.
   - Add the entry to `## [Unreleased]` under the appropriate category heading

#### Step 4: Stamp version header (only when a version mode or explicit version is given)

If the user passed `release`, `rc`, `beta`, or an explicit version string as an argument:

1. Auto-compute the next version (see "Auto-Computing the Next Version" above), or use the explicit version provided
2. Insert the version header immediately after `## [Unreleased]`
3. For `rc`/`beta` or an explicit prerelease version (e.g., `9.7.0-rc.10`): collapse prior prerelease sections of the same base version into the new section
4. Update version diff links at the bottom of the file
5. **Verify** the computed version looks correct

If no argument was passed, skip this step — entries stay in `## [Unreleased]`.

#### Step 5: Verify and finalize

1. **Verify formatting**:
   - Bold description with period
   - Proper PR link (with `#` prefix for Shakapacker)
   - Proper author link
   - Consistent with existing entries
   - File ends with a newline character
   - **No duplicate section headings** (e.g., don't create two `### Fixed` sections — merge entries into the existing heading)
2. **Verify version sections are in order** (Unreleased → newest tag → older tags)
3. **Verify version diff links** at the bottom of the file are correct (compare links MUST use the `v` prefix to match git tags)
4. **Run linting** after making changes:

   ```bash
   yarn lint
   ```

5. **Show the user** a summary of what was done:
   - Which version sections were created
   - Which entries were moved from Unreleased
   - Which new entries were added
   - Which PRs were skipped (and why)
6. If in `release`/`rc`/`beta` mode or explicit-version mode, **automatically commit, push, and open a PR**:
   - Verify the working tree only has `CHANGELOG.md` changes; if there are other uncommitted changes, warn the user and stop
   - Verify the current branch is `main` (`git branch --show-current`); if not, warn the user and stop
   - Create a feature branch (e.g., `changelog-v9.6.0-rc.1`)
   - Stage only `CHANGELOG.md` (`git add CHANGELOG.md`) and commit with message `Update CHANGELOG.md for vX.Y.Z` (using the stamped version)
   - Push and open a PR with the changelog diff as the body
   - If the push or PR creation fails, the CHANGELOG is already stamped locally — fix the issue and retry manually
   - Remind the user to run `bundle exec rake release` (no args) after merge to publish and auto-create the GitHub release

### For Prerelease Versions (RC and Beta)

When the user passes `rc` or `beta` as an argument (or when creating a prerelease section manually):

1. **Find the latest tag** (stable or prerelease) using semver sort:

   ```bash
   git tag -l 'v*' --sort=-v:refname | head -10
   ```

2. **Auto-compute the next prerelease version** using the process in "Auto-Computing the Next Version" above.

3. **Use npm semver format** for the version header:
   - RC: `## [v9.6.0-rc.1]`
   - Beta: `## [v9.6.0-beta.2]`

4. **Always collapse prior prereleases into the current prerelease** (this is the default behavior):
   - Combine all prior prerelease changelog entries into the new prerelease version section
   - Remove previous prerelease version sections (e.g., remove `## [v9.6.0-rc.0]` when creating `## [v9.6.0-rc.1]`)
   - When collapsing, **consolidate duplicate category headings** — if both the Unreleased section and a prior prerelease section have `### Fixed`, merge all entries under a single `### Fixed` heading
   - **Remove orphaned version diff links** at the bottom of the file for collapsed prerelease sections
   - Add any new user-visible changes from commits since the last prerelease
   - Update version diff links to point from the last stable version to the new prerelease
   - This keeps the changelog clean with a single prerelease section that accumulates all changes since the last stable release

**Note**: The new version header must be inserted **immediately after `## [Unreleased]`** (see Step 4). This ensures correct ordering of version headers.

### For Prerelease to Stable Version Release

When releasing from prerelease to a stable version (e.g., v9.6.0-rc.1 → v9.6.0):

1. **Remove all prerelease version labels** from the changelog:
   - Change `## [v9.6.0-rc.0]`, `## [v9.6.0-rc.1]`, etc. to a single `## [v9.6.0]` section
   - Also handle beta versions: `## [v9.6.0-beta.1]` etc.
   - Combine all prerelease entries into the stable release section

2. **Consolidate duplicate entries**:
   - If bug fixes or changes were made to features introduced in earlier prereleases, keep only the final state
   - Remove redundant changelog entries for fixes to prerelease features
   - Keep the most recent/accurate description of each change

3. **Update version diff links** at the bottom to point to the stable version

## Examples

Run this command to see real formatting examples from the codebase:

```bash
grep -A 3 "^### " CHANGELOG.md | head -30
```

### Good Entry Example

```markdown
- **Enhanced error handling for better security and debugging**. [PR #786](https://github.com/shakacode/shakapacker/pull/786) by [justin808](https://github.com/justin808).
  - Path validation now properly reports permission errors instead of silently handling them
  - Module loading errors now include original error context for easier troubleshooting
  - Improved security by only catching ENOENT errors in path resolution, rethrowing permission and access errors
```

### Entry with Sub-bullets Example

```markdown
- **HTTP 103 Early Hints support** for faster asset loading. [PR #722](https://github.com/shakacode/shakapacker/pull/722) by [justin808](https://github.com/justin808). Automatically sends early hints when `early_hints: enabled: true` in `shakapacker.yml`. Works with `append_javascript_pack_tag`/`append_stylesheet_pack_tag`, supports per-controller/action configuration, and includes helpers like `configure_pack_early_hints` and `skip_send_pack_early_hints`. Requires Rails 5.2+ and HTTP/2-capable server. See [Early Hints Guide](docs/early_hints.md).
```

### Breaking Change Example

```markdown
- **Breaking: SWC default configuration now uses `loose: false`**. [PR #658](https://github.com/shakacode/shakapacker/pull/658) by [justin808](https://github.com/justin808). See [v9 Upgrade Guide - SWC Loose Mode](./docs/v9_upgrade.md#swc-loose-mode-breaking-change-v910) for migration details.
```

## Additional Notes

- Keep descriptions concise but informative
- Focus on the "what" and "why", not the "how"
- Use past tense for the description
- Be consistent with existing formatting in the changelog
- Always ensure the file ends with a trailing newline
