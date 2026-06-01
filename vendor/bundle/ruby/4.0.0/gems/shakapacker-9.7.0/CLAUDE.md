# Shakapacker Project Guidelines

## Critical Requirements

- **ALWAYS end all files with a trailing newline character.** This is required by the project's linting rules.
- **ALWAYS use `bundle exec` prefix when running Ruby commands** (rubocop, rspec, rake, etc.)
- **ALWAYS run `bundle exec rubocop` before committing Ruby changes**
- **ALWAYS run `yarn lint` before committing JavaScript changes**

## Testing

- Run corresponding RSpec tests when changing source files
- For example, when changing `lib/shakapacker/foo.rb`, run `spec/shakapacker/foo_spec.rb`
- Run the full test suite with `bundle exec rspec` before pushing
- **Use explicit RSpec spy assertions** - prefer `have_received`/`not_to have_received` over indirect counter patterns
  - Good: `expect(Open3).to have_received(:capture3).with(anything, hook_command, anything)`
  - Good: `expect(Open3).not_to have_received(:capture3).with(anything, hook_command, anything)`
  - Avoid: `call_count += 1` followed by `expect(call_count).to eq(1)`

## Code Style

- Follow existing code conventions in the file you're editing
- Use the project's existing patterns and utilities
- No unnecessary comments unless requested
- Keep changes focused and minimal - avoid extraneous diffs

## Git Workflow

- Create feature branches for all changes
- Never push directly to main branch
- Create small, focused PRs that are easy to review
- Always create a PR immediately after pushing changes

## Changelog

- **Update CHANGELOG.md for user-visible changes only** (features, bug fixes, breaking changes, deprecations, performance improvements)
- **Do NOT add entries for**: linting, formatting, refactoring, tests, or documentation fixes
- **Format**: `[PR #123](https://github.com/shakacode/shakapacker/pull/123) by [username](https://github.com/username)` (Shakapacker uses `#` in PR links)
- **Use `/update-changelog` command** for guided changelog updates with automatic formatting
- **Version management**: Run `bundle exec rake update_changelog` after releases to update version headers
- **Examples**: Run `grep -A 3 "^### " CHANGELOG.md | head -30` to see real formatting examples

## Open Source Maintainability

- **Prefer removing complexity over adding configuration.** If a default causes problems, consider removing the default rather than adding an option to disable it.
- **Every config option is maintenance surface.** Prefer convention over configuration. Don't add options for <10% of users — let them customize via existing extension points (e.g., custom webpack config).
- **"No is temporary, yes is forever."** Adding a feature creates a permanent maintenance obligation. Reject features that solve one user's niche problem but add complexity for everyone.
- **Security-safe defaults over convenient defaults.** Don't ship permissive defaults (e.g., `Access-Control-Allow-Origin: *`) just for convenience — make users opt in to less-secure configurations.
- **Don't refactor adjacent code in feature PRs.** Keep PRs focused. If you spot something to clean up, do it in a separate PR.

## Shakapacker-Specific

- This gem supports both webpack and rspack configurations
- Test changes with both bundlers when modifying core functionality
- Be aware of the dual package.json/Gemfile dependency management

## Conductor Environment

- **Version manager support**: The setup script detects mise, asdf, or direct PATH tools (rbenv/nvm/nodenv)
- **bin/conductor-exec**: Use this wrapper for commands when tool versions aren't detected correctly in Conductor's non-interactive shell
  - Example: `bin/conductor-exec bundle exec rubocop`
  - The wrapper uses `mise exec` if mise is available, otherwise falls back to direct execution
- **conductor.json scripts** already use this wrapper, so you typically don't need to use it manually
