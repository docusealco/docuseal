# RuboCop Usage Guide

## Overview

A tale of two RuboCop plugin gems.

### RuboCop Gradual

This project uses `rubocop_gradual` instead of vanilla RuboCop for code style checking. The `rubocop_gradual` tool allows for gradual adoption of RuboCop rules by tracking violations in a lock file.

### RuboCop LTS

This project uses `rubocop-lts` to ensure, on a best-effort basis, compatibility with Ruby >= 1.9.2.
RuboCop rules are meticulously configured by the `rubocop-lts` family of gems to ensure that a project is compatible with a specific version of Ruby. See: https://rubocop-lts.gitlab.io for more.

## Checking RuboCop Violations

To check for RuboCop violations in this project, always use:

```bash
bundle exec rake rubocop_gradual:check
```

**Do not use** the standard RuboCop commands like:
- `bundle exec rubocop`
- `rubocop`

## Understanding the Lock File

The `.rubocop_gradual.lock` file tracks all current RuboCop violations in the project. This allows the team to:

1. Prevent new violations while gradually fixing existing ones
2. Track progress on code style improvements
3. Ensure CI builds don't fail due to pre-existing violations

## Common Commands

- **Check violations**
    - `bundle exec rake rubocop_gradual`
    - `bundle exec rake rubocop_gradual:check`
- **(Safe) Autocorrect violations, and update lockfile if no new violations**
  - `bundle exec rake rubocop_gradual:autocorrect`
- **Force update the lock file (w/o autocorrect) to match violations present in code**
  - `bundle exec rake rubocop_gradual:force_update`

## Workflow

1. Before submitting a PR, run `bundle exec rake rubocop_gradual:autocorrect`
   a. or just the default `bundle exec rake`, as autocorrection is a pre-requisite of the default task.
2. If there are new violations, either:
   - Fix them in your code
   - Run `bundle exec rake rubocop_gradual:force_update` to update the lock file (only for violations you can't fix immediately)
3. Commit the updated `.rubocop_gradual.lock` file along with your changes

## Never add inline RuboCop disables

Do not add inline `rubocop:disable` / `rubocop:enable` comments anywhere in the codebase (including specs, except when following the few existing `rubocop:disable` patterns for a rule already being disabled elsewhere in the code). We handle exceptions in two supported ways:

- Permanent/structural exceptions: prefer adjusting the RuboCop configuration (e.g., in `.rubocop.yml`) to exclude a rule for a path or file pattern when it makes sense project-wide.
- Temporary exceptions while improving code: record the current violations in `.rubocop_gradual.lock` via the gradual workflow:
  - `bundle exec rake rubocop_gradual:autocorrect` (preferred; will autocorrect what it can and update the lock only if no new violations were introduced)
  - If needed, `bundle exec rake rubocop_gradual:force_update` (as a last resort when you cannot fix the newly reported violations immediately)

In general, treat the rules as guidance to follow; fix violations rather than ignore them. For example, RSpec conventions in this project expect `described_class` to be used in specs that target a specific class under test.

## Benefits of rubocop_gradual

- Allows incremental adoption of code style rules
- Prevents CI failures due to pre-existing violations
- Provides a clear record of code style debt
- Enables focused efforts on improving code quality over time
