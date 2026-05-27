## [Unreleased](https://github.com/fgrehm/letter_opener_web/compare/v3.0.0...master)

## [3.0.0](https://github.com/fgrehm/letter_opener_web/compare/v2.0.0...v3.0.0)

### Breaking
  - Drop EoL'd Rubies and Rails - now requires Ruby 3.1+ and Rails 6.1+.

### Changes
  - Reliably strip Attachment links from the sidebar. [#132](https://github.com/fgrehm/letter_opener_web/pull/134)

### Additions
  - Allow dot (`.`) character in attachment file names. [#131](https://github.com/fgrehm/letter_opener_web/pull/131)
  - Add dark mode. [#119](https://github.com/fgrehm/letter_opener_web/pull/119)

## [v2.0.0](https://github.com/fgrehm/letter_opener_web/compare/v1.4.1...v2.0.0)

  - Require Rails >= 5.2, run tests against Rails 6.1 [#113](https://github.com/fgrehm/letter_opener_web/pull/113)
  - Inline CSS and Javascript, to avoid dependency on asset pipeline [#113](https://github.com/fgrehm/letter_opener_web/pull/113)
  - Upgrade to Bootstrap 5.1.1 [#113](https://github.com/fgrehm/letter_opener_web/pull/113)
  - Add rexml gem into dependency for Ruby 3.0 [#106](https://github.com/fgrehm/letter_opener_web/pull/106)
  - Add routes for Rails API mode [#69](https://github.com/fgrehm/letter_opener_web/pull/69)
  - Prevent name conflict with `Letter` class [#108](https://github.com/fgrehm/letter_opener_web/pull/108)
  - Add Rails' built-in CSRF protection [#111](https://github.com/fgrehm/letter_opener_web/pull/111)
  - Add Rails' CSP nonce to the script tag [#112](https://github.com/fgrehm/letter_opener_web/pull/112)
  - Update dev dependencies [#113](https://github.com/fgrehm/letter_opener_web/pull/113)
  - Switched to using GitHub actions as CI for the project [#113](https://github.com/fgrehm/letter_opener_web/pull/113)

## [1.4.1](https://github.com/fgrehm/letter_opener_web/compare/v1.4.0...v1.4.1) (Oct 5, 2021)

  - Ensure letter is within letters base path [#110](https://github.com/fgrehm/letter_opener_web/pull/110)

## [1.4.0](https://github.com/fgrehm/letter_opener_web/compare/v1.3.4...v1.4.0) (Jan 29, 2020)

  - Removed the dependency on the asset pipeline. Good news for API-only apps! [#83](https://github.com/fgrehm/letter_opener_web/pull/83)
  - Avoid `require_dependency` if Zeitwerk is enabled [#98](https://github.com/fgrehm/letter_opener_web/pull/98)
  - Drop support for old rubies and rails. Ruby 2.5+ is supported and Rails 4 is no longer tested [#100](https://github.com/fgrehm/letter_opener_web/pull/100)

## [1.3.4](https://github.com/fgrehm/letter_opener_web/compare/v1.3.3...v1.3.4) (Apr 04, 2018)

### Fixed

  - Due to a load order issue, sometimes the main `ApplicationController` was used by this gem (unnecessary) [#82](https://github.com/fgrehm/letter_opener_web/pull/82)

## [1.3.3](https://github.com/fgrehm/letter_opener_web/compare/v1.3.2...v1.3.3) (Jan 29, 2018)

  - Set `LAUNCHY_DRY_RUN` explicitly to avoid `Launchy::CommandNotFoundError` [#75](https://github.com/fgrehm/letter_opener_web/pull/75)
  - Update Ruby matrix for test to include more recent versions [#77](https://github.com/fgrehm/letter_opener_web/pull/77)

## [1.3.2](https://github.com/fgrehm/letter_opener_web/compare/v1.3.1...v1.3.2) (Jan 14, 2018)

  - Disable Launchy with ENV to avoid redefining the whole delivery method [#73](https://github.com/fgrehm/letter_opener_web/pull/73)
  - Fix new Rubocop warnings [#72](https://github.com/fgrehm/letter_opener_web/pull/72)
  - Hover state fixed to only highlight `tbody>tr` [#70](https://github.com/fgrehm/letter_opener_web/pull/70)
  - Use `ActiveSupport.on_load` to make sure we don't have load order issues [#66](https://github.com/fgrehm/letter_opener_web/pull/66)

## [1.3.1](https://github.com/fgrehm/letter_opener_web/compare/v1.3.0...v1.3.1) (Feb 04, 2017)

  - Remove warnings about unused variables [#45](https://github.com/fgrehm/letter_opener_web/pull/45)
  - Remove Rails 5 deprecation warnings [#54](https://github.com/fgrehm/letter_opener_web/pull/54)

## [1.3.0](https://github.com/fgrehm/letter_opener_web/compare/v1.2.3...v1.3.0) (Feb 02, 2015)

  - Depend on `railties` and `actionmailer` [#38](https://github.com/fgrehm/letter_opener_web/pull/38)

## [1.2.3](https://github.com/fgrehm/letter_opener_web/compare/v1.2.2...v1.2.3) (Sep 12, 2014)

  - Fix exception with `sprockets-rails` >= `2.1.4` [#32](https://github.com/fgrehm/letter_opener_web/issues/32) / [#33](https://github.com/fgrehm/letter_opener_web/pull/33)

## [1.2.2](https://github.com/fgrehm/letter_opener_web/compare/v1.2.1...v1.2.2) (Jul 17, 2014)

  - Precompile glyphicons [#30](https://github.com/fgrehm/letter_opener_web/pull/30)
  - Display letters count on the favicon [#29](https://github.com/fgrehm/letter_opener_web/pull/29)
  - Validate params passed in to the LettersController and return a 404 in case an email can't be found [#28](https://github.com/fgrehm/letter_opener_web/pull/28)

## [1.2.1](https://github.com/fgrehm/letter_opener_web/compare/v1.2.0...v1.2.1) (Apr 07, 2014)

  - Improve Rails 3 compatibility [#26](https://github.com/fgrehm/letter_opener_web/pull/26) / [#27](https://github.com/fgrehm/letter_opener_web/pull/27)

## [1.2.0](https://github.com/fgrehm/letter_opener_web/compare/v1.1.3...v1.2.0) (Apr 07, 2014)

  - Add support for removing a single email [#23](https://github.com/fgrehm/letter_opener_web/pull/23)
  - Move vendored assets into the `letter_opener_web` folder [#24](https://github.com/fgrehm/letter_opener_web/issues/24)
  - Avoid matching `<address>` when changing email links to open on new tabs [#22](https://github.com/fgrehm/letter_opener_web/pull/22)

## [1.1.3](https://github.com/fgrehm/letter_opener_web/compare/v1.1.2...v1.1.3) (Feb 21, 2014)

  - Include assets into `precompile` list [#21](https://github.com/fgrehm/letter_opener_web/pull/21)

## [1.1.2](https://github.com/fgrehm/letter_opener_web/compare/v1.1.1...v1.1.2) (Dec 12, 2013)

  - Nicely handle empty links [#18](https://github.com/fgrehm/letter_opener_web/pull/18)

## [1.1.1](https://github.com/fgrehm/letter_opener_web/compare/v1.1.0...v1.1.1) (Oct 15, 2013)

  - Fix deprecation warning on Rails 4 [#17](https://github.com/fgrehm/letter_opener_web/pull/17)

## [1.1.0](https://github.com/fgrehm/letter_opener_web/compare/v1.0.3...v1.1.0) (Aug 29, 2013)

  - "Relax" Rails dependency in order to use the gem on 4.0 [#15](https://github.com/fgrehm/letter_opener_web/issues/15)

## [1.0.3](https://github.com/fgrehm/letter_opener_web/compare/v1.0.2...v1.0.3) (May 29, 2013)

  - Fix clear button [#12](https://github.com/fgrehm/letter_opener_web/issues/12), tks to [@grumpit](https://github.com/grumpit)

## Previous

The changelog began with version 1.0.3 so any changes prior to that
can be seen by checking the tagged releases and reading git commit
messages.
