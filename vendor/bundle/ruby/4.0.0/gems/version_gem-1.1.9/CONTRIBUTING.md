# Contributing

Bug reports and pull requests are welcome on [CodeBerg][📜src-cb], [GitLab][📜src-gl], or [GitHub][📜src-gh].
This project should be a safe, welcoming space for collaboration, so contributors agree to adhere to
the [code of conduct][🤝conduct].

To submit a patch, please fork the project, create a patch with tests, and send a pull request.

Remember to [![Keep A Changelog][📗keep-changelog-img]][📗keep-changelog] if you make changes.

## Help out!

Take a look at the `reek` list which is the file called `REEK` and find something to improve.

Follow these instructions:

1. Fork the repository
2. Create a feature branch (`git checkout -b my-new-feature`)
3. Make some fixes.
4. Commit changes (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Make sure to add tests for it. This is important, so it doesn't break in a future release.
7. Create new Pull Request.

## Environment Variables for Local Development

Below are the primary environment variables recognized by stone_checksums (and its integrated tools). Unless otherwise noted, set boolean values to the string "true" to enable.

General/runtime
- DEBUG: Enable extra internal logging for this library (default: false)
- REQUIRE_BENCH: Enable `require_bench` to profile requires (default: false)
- CI: When set to true, adjusts default rake tasks toward CI behavior

Coverage (kettle-soup-cover / SimpleCov)
- K_SOUP_COV_DO: Enable coverage collection (default: true in .envrc)
- K_SOUP_COV_FORMATTERS: Comma-separated list of formatters (html, xml, rcov, lcov, json, tty)
- K_SOUP_COV_MIN_LINE: Minimum line coverage threshold (integer, e.g., 100)
- K_SOUP_COV_MIN_BRANCH: Minimum branch coverage threshold (integer, e.g., 100)
- K_SOUP_COV_MIN_HARD: Fail the run if thresholds are not met (true/false)
- K_SOUP_COV_MULTI_FORMATTERS: Enable multiple formatters at once (true/false)
- K_SOUP_COV_OPEN_BIN: Path to browser opener for HTML (empty disables auto-open)
- MAX_ROWS: Limit console output rows for simplecov-console (e.g., 1)
  Tip: When running a single spec file locally, you may want `K_SOUP_COV_MIN_HARD=false` to avoid failing thresholds for a partial run.

GitHub API and CI helpers
- GITHUB_TOKEN or GH_TOKEN: Token used by `ci:act` and release workflow checks to query GitHub Actions status at higher rate limits

Releasing and signing
- SKIP_GEM_SIGNING: If set, skip gem signing during build/release
- GEM_CERT_USER: Username for selecting your public cert in `certs/<USER>.pem` (defaults to $USER)
- SOURCE_DATE_EPOCH: Reproducible build timestamp. `kettle-release` will set this automatically for the session.

Git hooks and commit message helpers (exe/kettle-commit-msg)
- GIT_HOOK_BRANCH_VALIDATE: Branch name validation mode (e.g., `jira`) or `false` to disable
- GIT_HOOK_FOOTER_APPEND: Append a footer to commit messages when goalie allows (true/false)
- GIT_HOOK_FOOTER_SENTINEL: Required when footer append is enabled — a unique first-line sentinel to prevent duplicates
- GIT_HOOK_FOOTER_APPEND_DEBUG: Extra debug output in the footer template (true/false)

For a quick starting point, this repository’s `.envrc` shows sane defaults, and `.env.local` can override them locally.

## Appraisals

From time to time the [appraisal2][🚎appraisal2] gemfiles in `gemfiles/` will need to be updated.
They are created and updated with the commands:

```console
bin/rake appraisal:update
```

When adding an appraisal to CI, check the [runner tool cache][🏃‍♂️runner-tool-cache] to see which runner to use.

## The Reek List

Take a look at the `reek` list which is the file called `REEK` and find something to improve.

To refresh the `reek` list:

```console
bundle exec reek > REEK
```

## Run Tests

To run all tests

```console
bundle exec rake test
```

### Spec organization (required)

- One spec file per class/module. For each class or module under `lib/`, keep all of its unit tests in a single spec file under `spec/` that mirrors the path and file name exactly: `lib/version_gem/release_cli.rb` -> `spec/version_gem/release_cli_spec.rb`.
- Never add a second spec file for the same class/module. Examples of disallowed names: `*_more_spec.rb`, `*_extra_spec.rb`, `*_status_spec.rb`, or any other suffix that still targets the same class. If you find yourself wanting a second file, merge those examples into the canonical spec file for that class/module.
- Exception: Integration specs that intentionally span multiple classes. Place these under `spec/integration/` (or a clearly named integration folder), and do not directly mirror a single class. Name them after the scenario, not a class.
- Migration note: If a duplicate spec file exists, move all examples into the canonical file and delete the duplicate. Do not leave stubs or empty files behind.

## Lint It

Run all the default tasks, which includes running the gradually autocorrecting linter, `rubocop-gradual`.

```console
bundle exec rake
```

Or just run the linter.

```console
bundle exec rake rubocop_gradual:autocorrect
```

For more detailed information about using RuboCop in this project, please see the [RUBOCOP.md](RUBOCOP.md) guide. This project uses `rubocop_gradual` instead of vanilla RuboCop, which requires specific commands for checking violations.

### Important: Do not add inline RuboCop disables

Never add `# rubocop:disable ...` / `# rubocop:enable ...` comments to code or specs (except when following the few existing `rubocop:disable` patterns for a rule already being disabled elsewhere in the code). Instead:

- Prefer configuration-based exclusions when a rule should not apply to certain paths or files (e.g., via `.rubocop.yml`).
- When a violation is temporary and you plan to fix it later, record it in `.rubocop_gradual.lock` using the gradual workflow:
  - `bundle exec rake rubocop_gradual:autocorrect` (preferred)
  - `bundle exec rake rubocop_gradual:force_update` (only when you cannot fix the violations immediately)

As a general rule, fix style issues rather than ignoring them. For example, our specs should follow RSpec conventions like using `described_class` for the class under test.

## Contributors

Your picture could be here!

[![Contributors][🖐contributors-img]][🖐contributors]

Made with [contributors-img][🖐contrib-rocks].

Also see GitLab Contributors: [https://gitlab.com/ruby-oauth/version_gem/-/graphs/main][🚎contributors-gl]

## For Maintainers

### One-time, Per-maintainer, Setup

**IMPORTANT**: To sign a build,
a public key for signing gems will need to be picked up by the line in the
`gemspec` defining the `spec.cert_chain` (check the relevant ENV variables there).
All releases to RubyGems.org are signed releases.
See: [RubyGems Security Guide][🔒️rubygems-security-guide]

NOTE: To build without signing the gem set `SKIP_GEM_SIGNING` to any value in the environment.

### To release a new version:

#### Automated process

1. Update version.rb to contian the correct version-to-be-released.
2. Run `bundle exec kettle-changelog`.
3. Run `bundle exec kettle-release`.

#### Manual process

1. Run `bin/setup && bin/rake` as a "test, coverage, & linting" sanity check
2. Update the version number in `version.rb`, and ensure `CHANGELOG.md` reflects changes
3. Run `bin/setup && bin/rake` again as a secondary check, and to update `Gemfile.lock`
4. Run `git commit -am "🔖 Prepare release v<VERSION>"` to commit the changes
5. Run `git push` to trigger the final CI pipeline before release, and merge PRs
    - NOTE: Remember to [check the build][🧪build].
6. Run `export GIT_TRUNK_BRANCH_NAME="$(git remote show origin | grep 'HEAD branch' | cut -d ' ' -f5)" && echo $GIT_TRUNK_BRANCH_NAME`
7. Run `git checkout $GIT_TRUNK_BRANCH_NAME`
8. Run `git pull origin $GIT_TRUNK_BRANCH_NAME` to ensure latest trunk code
9. Optional for older Bundler (< 2.7.0): Set `SOURCE_DATE_EPOCH` so `rake build` and `rake release` use the same timestamp and generate the same checksums
    - If your Bundler is >= 2.7.0, you can skip this; builds are reproducible by default.
    - Run `export SOURCE_DATE_EPOCH=$EPOCHSECONDS && echo $SOURCE_DATE_EPOCH`
    - If the echo above has no output, then it didn't work.
    - Note: `zsh/datetime` module is needed, if running `zsh`.
    - In older versions of `bash` you can use `date +%s` instead, i.e. `export SOURCE_DATE_EPOCH=$(date +%s) && echo $SOURCE_DATE_EPOCH`
10. Run `bundle exec rake build`
11. Run `bin/gem_checksums` (more context [1][🔒️rubygems-checksums-pr], [2][🔒️rubygems-guides-pr])
    to create SHA-256 and SHA-512 checksums. This functionality is provided by the `stone_checksums`
    [gem][💎stone_checksums].
    - The script automatically commits but does not push the checksums
12. Sanity check the SHA256, comparing with the output from the `bin/gem_checksums` command:
    - `sha256sum pkg/<gem name>-<version>.gem`
13. Run `bundle exec rake release` which will create a git tag for the version,
    push git commits and tags, and push the `.gem` file to [rubygems.org][💎rubygems]

[📜src-gl]: https://gitlab.com/ruby-oauth/version_gem/
[📜src-cb]: https://codeberg.org/ruby-oauth/version_gem
[📜src-gh]: https://github.com/ruby-oauth/version_gem
[🧪build]: https://github.com/ruby-oauth/version_gem/actions
[🤝conduct]: https://gitlab.com/ruby-oauth/version_gem/-/blob/main/CODE_OF_CONDUCT.md
[🖐contrib-rocks]: https://contrib.rocks
[🖐contributors]: https://github.com/ruby-oauth/version_gem/graphs/contributors
[🚎contributors-gl]: https://gitlab.com/ruby-oauth/version_gem/-/graphs/main
[🖐contributors-img]: https://contrib.rocks/image?repo=ruby-oauth/version_gem
[💎rubygems]: https://rubygems.org
[🔒️rubygems-security-guide]: https://guides.rubygems.org/security/#building-gems
[🔒️rubygems-checksums-pr]: https://github.com/rubygems/rubygems/pull/6022
[🔒️rubygems-guides-pr]: https://github.com/rubygems/guides/pull/325
[💎stone_checksums]: https://github.com/galtzo-floss/stone_checksums
[📗keep-changelog]: https://keepachangelog.com/en/1.0.0/
[📗keep-changelog-img]: https://img.shields.io/badge/keep--a--changelog-1.0.0-FFDD67.svg?style=flat
[📌semver-breaking]: https://github.com/semver/semver/issues/716#issuecomment-869336139
[📌major-versions-not-sacred]: https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred.html
[🚎appraisal2]: https://github.com/appraisal-rb/appraisal2
[🏃‍♂️runner-tool-cache]: https://github.com/ruby/ruby-builder/releases/tag/toolcache
