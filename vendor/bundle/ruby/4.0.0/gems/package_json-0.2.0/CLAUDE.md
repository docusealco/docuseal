# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## ⚠️ CRITICAL REQUIREMENTS

**BEFORE EVERY COMMIT/PUSH:**

1. **ALWAYS run `bundle exec rubocop` and fix ALL violations**
2. **ALWAYS ensure files end with a newline character**
3. **NEVER push without running full lint check first**

These requirements are non-negotiable. CI will fail if not followed.

## Development Commands

### Essential Commands

- **Install dependencies**: `bundle install`
- **Run tests**: `rake spec` or `bundle exec rspec`
- **Linting** (MANDATORY BEFORE EVERY COMMIT):
  - **REQUIRED**: `bundle exec rubocop` - Must pass with zero offenses
  - Auto-fix RuboCop violations: `bundle exec rubocop -a`
- **⚠️ MANDATORY BEFORE GIT PUSH**: `bundle exec rubocop` and fix ALL
  violations + ensure trailing newlines
- **Default task** (runs tests and rubocop): `rake`

## Changelog

- **Update CHANGELOG.md for user-visible changes only** (features, bug fixes,
  breaking changes, deprecations, performance improvements)
- **Do NOT add entries for**: linting, formatting, refactoring, tests, or
  documentation fixes
- **Format**:
  `[PR 123](https://github.com/shakacode/package_json/pull/123) by [username](https://github.com/username)`
  (no hash in PR number)
- **Use `/update-changelog` command** for guided changelog updates with
  automatic formatting
- **Version management**: Run `bundle exec rake update_changelog` after releases
  to update version headers (if task exists)
- **Examples**: Run `grep -A 3 "^#### " CHANGELOG.md | head -30` to see real
  formatting examples

## ⚠️ FORMATTING RULES

**RuboCop is the SOLE authority for formatting Ruby files. NEVER manually format
code.**

### Standard Workflow

1. Make code changes
2. Run `bundle exec rubocop -a` to auto-fix violations
3. Commit changes

### Debugging Formatting Issues

- Check for violations: `bundle exec rubocop`
- Fix violations: `bundle exec rubocop -a`
- If CI fails on formatting, always run automated fixes, never manual fixes

## Project Architecture

### Core Components

This is a Ruby gem that provides a Ruby interface for managing `package.json`
files and JavaScript package managers.

#### Ruby Side (`lib/package_json/`)

- **`lib/package_json.rb`**: Main entry point and core PackageJson class
- **`lib/package_json/manager.rb`**: Base class for package manager abstraction
- **`lib/package_json/managers/`**: Specific implementations for npm, yarn,
  pnpm, bun, etc.

### Build System

- **Ruby**: Standard gemspec-based build (see `package_json.gemspec`)
- **Testing**: RSpec for Ruby tests
- **Linting**: RuboCop for Ruby

## Type Signatures & Documentation

**This project uses RBS (Ruby Signature) files for type documentation**

Everything should be captured in the type definitions, including private
methods.

## Important Notes

- This gem provides a "middle-level" abstraction over JavaScript package
  managers
- Supports npm, yarn (classic and berry), pnpm, and bun
- Does not capture or intercept package manager output by default
- Uses `Kernel.system` under the hood for package manager operations

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/shakacode/package_json.
