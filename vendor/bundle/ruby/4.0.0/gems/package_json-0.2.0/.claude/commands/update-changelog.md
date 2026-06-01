# Update Changelog

You are helping to add an entry to the CHANGELOG.md file for the PackageJson
project.

## Critical Requirements

1. **User-visible changes only**: Only add changelog entries for user-visible
   changes:
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
- **Bold description of change**.
  [PR 1818](https://github.com/shakacode/package_json/pull/1818) by
  [username](https://github.com/username). Optional additional context or
  details.
```

**Important formatting rules**:

- Start with a dash and space: `- `
- Use **bold** for the main description
- End the bold description with a period before the link
- Always link to the PR:
  `[PR 1818](https://github.com/shakacode/package_json/pull/1818)` - **NO hash
  symbol**
- Always link to the author: `by [username](https://github.com/username)`
- End with a period after the author link
- Additional details can be added after the main entry, using proper indentation
  for multi-line entries

### Breaking Changes Format

For breaking changes, use this format:

```markdown
- **Feature Name**: Description of the breaking change. See migration guide
  below. [PR 1818](https://github.com/shakacode/package_json/pull/1818) by
  [username](https://github.com/username).

**Migration Guide:**

1. Step one
2. Step two
```

### Category Organization

Entries should be organized under these section headings. The project uses both
standard and custom headings:

**Standard headings** (from keepachangelog.com) - use these for most changes:

- `#### Added` - New features
- `#### Changed` - Changes to existing functionality
- `#### Deprecated` - Deprecation notices
- `#### Removed` - Removed features
- `#### Fixed` - Bug fixes
- `#### Security` - Security-related changes
- `#### Improved` - Improvements to existing features

**Custom headings** (project-specific) - use sparingly when standard headings
don't fit:

- `#### Breaking Changes` - Breaking changes with migration guides
- `#### Performance` - Performance improvements

**Prefer standard headings.** Only use custom headings when the change needs
more specific categorization.

**Only include section headings that have entries.**

### Version Management

After adding entries, use the rake task to manage version headers:

```bash
bundle exec rake update_changelog
```

This will:

- Add headers for the new version
- Update version diff links at the bottom of the file

## Process

### For Regular Changelog Updates

1. **Determine the correct version tag to compare against**:
   - First, check the tag dates:
     `git log --tags --simplify-by-decoration --pretty="format:%ai %d" | head -10`
   - Find the latest version tag and its date
   - Compare main branch date to the tag date
   - If the tag is NEWER than main, it means main needs to be updated to include
     the tag's commits
   - **CRITICAL**: Always use `git log TAG..BRANCH` to find commits that are in
     the tag but not in the branch, as the tag may be ahead

2. **Check commits and version boundaries**:
   - Run `git log --oneline LAST_TAG..main` to see commits since the last
     release
   - Also check `git log --oneline main..LAST_TAG` to see if the tag is ahead of
     main
   - If the tag is ahead, entries in "Unreleased" section may actually belong to
     that tagged version
   - Identify which commits contain user-visible changes
   - Extract PR numbers and author information from commit messages
   - **Never ask the user for PR details** - get them from the git history

3. **Validate** that changes are user-visible (per the criteria above). If not
   user-visible, skip those commits.

4. **Read the current CHANGELOG.md** to understand the existing structure and
   formatting.

5. **Determine where entries should go**:
   - If the latest version tag is NEWER than main branch, move entries from
     "Unreleased" to that version section
   - If main is ahead of the latest tag, add new entries to "Unreleased"
   - Always verify the version date in CHANGELOG.md matches the actual tag date

6. **Add or move entries** to the appropriate section under appropriate category
   headings.
   - **CRITICAL**: When moving entries from "Unreleased" to a version section,
     merge them with existing entries under the same category heading
   - **NEVER create duplicate section headings** (e.g., don't create two "###
     Fixed" sections)
   - If the version section already has a category heading (e.g., "### Fixed"),
     add the moved entries to that existing section
   - Maintain the category order as defined above

7. **Verify formatting**:
   - Bold description with period
   - Proper PR link (NO hash symbol)
   - Proper author link
   - Consistent with existing entries
   - File ends with a newline character

8. **Run linting** after making changes:

   ```bash
   bundle exec rubocop
   yarn run prettier
   ```

9. **Show the user** the added or moved entries and explain what was done.

### For Beta to Non-Beta Version Release

When releasing from beta to a stable version (e.g., v1.1.0-beta.3 → v1.1.0):

1. **Remove all beta version labels** from the changelog:
   - Change `### [v1.1.0-beta.1]`, `### [v1.1.0-beta.2]`, etc. to a single
     `### [v1.1.0]` section
   - Combine all beta entries into the stable release section

2. **Consolidate duplicate entries**:
   - If bug fixes or changes were made to features introduced in earlier betas,
     keep only the final state
   - Remove redundant changelog entries for fixes to beta features
   - Keep the most recent/accurate description of each change

3. **Update version diff links** using `bundle exec rake update_changelog`

### For New Beta Version Release

When creating a new beta version, ask the user which approach to take:

**Option 1: Process changes since last beta**

- Only add entries for commits since the previous beta version
- Maintains detailed history of what changed in each beta

**Option 2: Collapse all prior betas into current beta**

- Combine all beta changelog entries into the new beta version
- Removes previous beta version sections
- Cleaner changelog with less version noise

After the user chooses, proceed with that approach.

## Examples

Run this command to see real formatting examples from the codebase:

```bash
grep -A 3 "^#### " CHANGELOG.md | head -30
```

### Good Entry Example

```markdown
- **New feature description**: Added helpful functionality that users will
  appreciate. [PR 123](https://github.com/shakacode/package_json/pull/123) by
  [username](https://github.com/username).
```

### Entry with Sub-bullets Example

```markdown
- **Multi-part feature**: Added new configuration options for enhanced
  functionality:
  - `option_name`: Description of the option and its purpose.
    [PR 123](https://github.com/shakacode/package_json/pull/123) by
    [username](https://github.com/username)
  - `another_option`: Description of another option.
    [PR 124](https://github.com/shakacode/package_json/pull/124) by
    [username](https://github.com/username)
```

### Breaking Change Example

```markdown
- **Method Removal**: Several deprecated methods have been removed. If you're
  using any of the following methods, you'll need to migrate:
  - `old_method_one()`
  - `old_method_two()`

**Migration Guide:**

To migrate:

1. Replace `old_method_one()` with `new_method()`
2. Update configuration to use new format
```

## Additional Notes

- Keep descriptions concise but informative
- Focus on the "what" and "why", not the "how"
- Use past tense for the description
- Be consistent with existing formatting in the changelog
- Always ensure the file ends with a trailing newline
- See CHANGELOG.md for additional contributor guidelines
