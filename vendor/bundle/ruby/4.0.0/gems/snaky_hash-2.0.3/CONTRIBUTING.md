## Contributing

Bug reports and pull requests are welcome on GitLab at [https://gitlab.com/oauth-xx/snaky_hash][🚎src-main]
. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct][🤝conduct].

To submit a patch, please fork the project and create a patch with tests.
Once you're happy with it send a pull request.

We [![Keep A Changelog][📗keep-changelog-img]][📗keep-changelog] so if you make changes, remember to update it.

## You can help!

Take a look at the `reek` list which is the file called `REEK` and find something to improve.

Simply follow these instructions:

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Make some fixes.
4. Commit your changes (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Make sure to add tests for it. This is important, so it doesn't break in a future release.
7. Create new Pull Request.

## Appraisals

From time to time the appraisal gemfiles in `gemfiles/` will need to be updated.
They are created and updated with the commands:

NOTE: We run on a [fork][🚎appraisal-fork] of Appraisal.

Please upvote the PR for `eval_gemfile` [support][🚎appraisal-eval-gemfile-pr]

```shell
BUNDLE_GEMFILE=Appraisal.root.gemfile bundle
BUNDLE_GEMFILE=Appraisal.root.gemfile bundle exec appraisal update
bundle exec rake rubocop_gradual:autocorrect
```

When adding an appraisal to CI check the [runner tool cache][🏃‍♂️runner-tool-cache] to see which runner to use.

## The Reek List

Take a look at the `reek` list which is the file called `REEK` and find something to improve.

To refresh the `reek` list:

```bash
bundle exec reek > REEK
```

## Run Tests

To run all tests

```bash
bundle exec rake test
```

## Lint It

Run all the default tasks, which includes running the gradually autocorrecting linter, `rubocop-gradual`.

```bash
bundle exec rake
```

Or just run the linter.

```bash
bundle exec rake rubocop_gradual:autocorrect
```

## Contributors

Your picture could be here!

[![Contributors][🖐contributors-img]][🖐contributors]

Made with [contributors-img][🖐contrib-rocks].

Also see GitLab Contributors: [https://gitlab.com/oauth-xx/snaky_hash/-/graphs/main][🚎contributors-gl]

## For Maintainers

### One-time, Per-maintainer, Setup

**IMPORTANT**: If you want to sign the build you create,
your public key for signing gems will need to be picked up by the line in the
`gemspec` defining the `spec.cert_chain` (check the relevant ENV variables there).
All releases to RubyGems.org will be signed.
See: [RubyGems Security Guide][🔒️rubygems-security-guide]

NOTE: To build without signing the gem you must set `SKIP_GEM_SIGNING` to some value in your environment.

### To release a new version:

1. Run `bin/setup && bin/rake` as a tests, coverage, & linting sanity check
2. Update the version number in `version.rb`, and ensure `CHANGELOG.md` reflects changes
3. Run `bin/setup && bin/rake` again as a secondary check, and to update `Gemfile.lock`
4. Run `git commit -am "🔖 Prepare release v<VERSION>"` to commit the changes
5. Run `git push` to trigger the final CI pipeline before release, & merge PRs
    - NOTE: Remember to [check the build][🧪build]!
6. Run `export GIT_TRUNK_BRANCH_NAME="$(git remote show origin | grep 'HEAD branch' | cut -d ' ' -f5)" && echo $GIT_TRUNK_BRANCH_NAME`
7. Run `git checkout $GIT_TRUNK_BRANCH_NAME`
8. Run `git pull origin $GIT_TRUNK_BRANCH_NAME` to ensure you will release the latest trunk code
9. Set `SOURCE_DATE_EPOCH` so `rake build` and `rake release` use same timestamp, and generate same checksums
    - Run `export SOURCE_DATE_EPOCH=$EPOCHSECONDS && echo $SOURCE_DATE_EPOCH`
    - If the echo above has no output, then it didn't work.
    - Note that you'll need the `zsh/datetime` module, if running `zsh`.
    - In older versions of `bash` you can use `date +%s` instead, i.e. `export SOURCE_DATE_EPOCH=$(date +%s) && echo $SOURCE_DATE_EPOCH`
10. Run `bundle exec rake build`
11. Run `bin/gem_checksums` (more context [1][🔒️rubygems-checksums-pr], [2][🔒️rubygems-guides-pr])
    to create SHA-256 and SHA-512 checksums. This functionality is provided by the `stone_checksums`
    [gem][💎stone_checksums].
    - Checksums will be committed automatically by the script, but not pushed
12. Run `bundle exec rake release` which will create a git tag for the version,
    push git commits and tags, and push the `.gem` file to [rubygems.org][💎rubygems]

[🚎src-main]: https://gitlab.com/oauth-xx/snaky_hash
[🧪build]: https://github.com/oauth-xx/snaky_hash/actions
[🤝conduct]: https://gitlab.com/oauth-xx/snaky_hash/-/blob/main/CODE_OF_CONDUCT.md
[🖐contrib-rocks]: https://contrib.rocks
[🖐contributors]: https://github.com/oauth-xx/snaky_hash/graphs/contributors
[🚎contributors-gl]: https://gitlab.com/oauth-xx/snaky_hash/-/graphs/main
[🖐contributors-img]: https://contrib.rocks/image?repo=oauth-xx/snaky_hash
[💎rubygems]: https://rubygems.org
[🔒️rubygems-security-guide]: https://guides.rubygems.org/security/#building-gems
[🔒️rubygems-checksums-pr]: https://github.com/rubygems/rubygems/pull/6022
[🔒️rubygems-guides-pr]: https://github.com/rubygems/guides/pull/325
[💎stone_checksums]: https://github.com/pboling/stone_checksums
[📗keep-changelog]: https://keepachangelog.com/en/1.0.0/
[📗keep-changelog-img]: https://img.shields.io/badge/keep--a--changelog-1.0.0-FFDD67.svg?style=flat
[📌semver-breaking]: https://github.com/semver/semver/issues/716#issuecomment-869336139
[📌major-versions-not-sacred]: https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred.html
[🚎appraisal-eval-gemfile-pr]: https://github.com/thoughtbot/appraisal/pull/248
[🚎appraisal-fork]: https://github.com/pboling/appraisal/tree/galtzo
[🏃‍♂️runner-tool-cache]: https://github.com/ruby/ruby-builder/releases/tag/toolcache
