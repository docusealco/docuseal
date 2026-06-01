# Changelog

[![SemVer 2.0.0][📌semver-img]][📌semver] [![Keep-A-Changelog 1.0.0][📗keep-changelog-img]][📗keep-changelog]

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][📗keep-changelog],
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html),
and [yes][📌major-versions-not-sacred], platform and engine support are part of the [public API][📌semver-breaking].
Please file a bug if you notice a violation of semantic versioning.

[📌semver]: https://semver.org/spec/v2.0.0.html
[📌semver-img]: https://img.shields.io/badge/semver-2.0.0-FFDD67.svg?style=flat
[📌semver-breaking]: https://github.com/semver/semver/issues/716#issuecomment-869336139
[📌major-versions-not-sacred]: https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred.html
[📗keep-changelog]: https://keepachangelog.com/en/1.0.0/
[📗keep-changelog-img]: https://img.shields.io/badge/keep--a--changelog-1.0.0-FFDD67.svg?style=flat

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [2.0.18] - 2025-11-08

- TAG: [v2.0.18][2.0.18t]
- COVERAGE: 100.00% -- 526/526 lines in 14 files
- BRANCH COVERAGE: 100.00% -- 178/178 branches in 14 files
- 90.48% documented

### Added

- [gh!683][gh!683], [gh!684][gh!684] - Improve documentation by @pboling
- [gh!686][gh!686]- Add Incident Response Plan by @pboling
- [gh!687][gh!687]- Add Threat Model by @pboling

### Changed

- [gh!685][gh!685] - upgrade kettle-dev v1.1.24 by @pboling
- upgrade kettle-dev v1.1.52 by @pboling
  - Add open collective donors to README

### Fixed

- [gh!690][gh!690], [gh!691][gh!691], [gh!692][gh!692] - Add yard-fence
  - handle braces within code fences in markdown properly by @pboling

### Security

[gh!683]: https://github.com/ruby-oauth/oauth2/pull/683
[gh!684]: https://github.com/ruby-oauth/oauth2/pull/684
[gh!685]: https://github.com/ruby-oauth/oauth2/pull/685
[gh!686]: https://github.com/ruby-oauth/oauth2/pull/686
[gh!687]: https://github.com/ruby-oauth/oauth2/pull/687
[gh!690]: https://github.com/ruby-oauth/oauth2/pull/690
[gh!691]: https://github.com/ruby-oauth/oauth2/pull/691
[gh!692]: https://github.com/ruby-oauth/oauth2/pull/692

## [2.0.17] - 2025-09-15

- TAG: [v2.0.17][2.0.17t]
- COVERAGE: 100.00% -- 526/526 lines in 14 files
- BRANCH COVERAGE: 100.00% -- 178/178 branches in 14 files
- 90.48% documented

### Added

- [gh!682][gh!682] - AccessToken: support Hash-based verb-dependent token transmission mode (e.g., `{get: :query, post: :header}`)

[gh!682]: https://github.com/ruby-oauth/oauth2/pull/682

## [2.0.16] - 2025-09-14

- TAG: [v2.0.16][2.0.16t]
- COVERAGE: 100.00% -- 520/520 lines in 14 files
- BRANCH COVERAGE: 100.00% -- 176/176 branches in 14 files
- 90.48% documented

### Added

- [gh!680][gh!680] - E2E example using mock test server added in v2.0.11 by @pboling
  - mock-oauth2-server upgraded to v2.3.0
    - https://github.com/navikt/mock-oauth2-server
  - `docker compose -f docker-compose-ssl.yml up -d --wait`
  - `ruby examples/e2e.rb`
  - `docker compose -f docker-compose-ssl.yml down`
  - mock server readiness wait is 90s
  - override via E2E_WAIT_TIMEOUT
- [gh!676][gh!676], [gh!679][gh!679] - Apache SkyWalking Eyes dependency license check by @pboling

### Changed

- [gh!678][gh!678] - Many improvements to make CI more resilient (past/future proof) by @pboling
- [gh!681][gh!681] - Upgrade to kettle-dev v1.1.19

[gh!676]: https://github.com/ruby-oauth/oauth2/pull/676
[gh!678]: https://github.com/ruby-oauth/oauth2/pull/678
[gh!679]: https://github.com/ruby-oauth/oauth2/pull/679
[gh!680]: https://github.com/ruby-oauth/oauth2/pull/680
[gh!681]: https://github.com/ruby-oauth/oauth2/pull/681

## [2.0.15] - 2025-09-08

- TAG: [v2.0.15][2.0.15t]
- COVERAGE: 100.00% -- 519/519 lines in 14 files
- BRANCH COVERAGE: 100.00% -- 174/174 branches in 14 files
- 90.48% documented

### Added

- [gh!671][gh!671] - Complete documentation example for Instagram by @pboling
- .env.local.example for contributor happiness
- note lack of builds for JRuby 9.2, 9.3 & Truffleruby 22.3, 23.0
  - [actions/runner - issues/2347][GHA-continue-on-error-ui]
  - [community/discussions/15452][GHA-allow-failure]
- [gh!670][gh!670] - AccessToken: verb-dependent token transmission mode by @mrj
  - e.g., Instagram GET=:query, POST/DELETE=:header

### Changed

- [gh!669][gh!669] - Upgrade to kettle-dev v1.1.9 by @pboling

### Fixed

- Remove accidentally duplicated lines, and fix typos in CHANGELOG.md
- point badge to the correct workflow for Ruby 2.3 (caboose.yml)

[gh!669]: https://github.com/ruby-oauth/oauth2/pull/669
[gh!670]: https://github.com/ruby-oauth/oauth2/pull/670
[gh!671]: https://github.com/ruby-oauth/oauth2/pull/671
[GHA-continue-on-error-ui]: https://github.com/actions/runner/issues/2347
[GHA-allow-failure]: https://github.com/orgs/community/discussions/15452

## [2.0.14] - 2025-08-31

- TAG: [v2.0.14][2.0.14t]
- COVERAGE: 100.00% -- 519/519 lines in 14 files
- BRANCH COVERAGE: 100.00% -- 174/174 branches in 14 files
- 90.48% documented

### Added

- improved documentation by @pboling
- [gh!665][gh!665] - Document Mutual TLS (mTLS) usage with example in README (connection_opts.ssl client_cert/client_key and auth_scheme: :tls_client_auth) by @pboling
- [gh!666][gh!666] - Document usage of flat query params using Faraday::FlatParamsEncoder, with example URI, in README by @pboling
  - Spec: verify flat params are preserved with Faraday::FlatParamsEncoder (skips on Faraday without FlatParamsEncoder)
- [gh!662][gh!662] - documentation notes in code comments and README highlighting OAuth 2.1 differences, with references, by @pboling
  - PKCE required for auth code,
  - exact redirect URI match,
  - implicit/password grants omitted,
  - avoid bearer tokens in query,
  - refresh token guidance for public clients,
  - simplified client definitions
- [gh!663][gh!663] - document how to implement an OIDC client with this gem in OIDC.md by @pboling
  - also, list libraries built on top of the oauth2 gem that implement OIDC
- [gh!664][gh!664] - README: Add example for JHipster UAA (Spring Cloud) password grant, converted from Postman/Net::HTTP by @pboling

[gh!662]: https://github.com/ruby-oauth/oauth2/pull/662
[gh!663]: https://github.com/ruby-oauth/oauth2/pull/663
[gh!664]: https://github.com/ruby-oauth/oauth2/pull/664
[gh!665]: https://github.com/ruby-oauth/oauth2/pull/665
[gh!666]: https://github.com/ruby-oauth/oauth2/pull/666

## [2.0.13] - 2025-08-30

- TAG: [v2.0.13][2.0.13t]
- COVERAGE: 100.00% -- 519/519 lines in 14 files
- BRANCH COVERAGE: 100.00% -- 174/174 branches in 14 files
- 90.48% documented

### Added

- [gh!656][gh!656] - Support revocation with URL-encoded parameters
- [gh!660][gh!660] - Inline yard documentation by @pboling
- [gh!660][gh!660] - Complete RBS types documentation by @pboling
- [gh!660][gh!660]- (more) Comprehensive documentation / examples by @pboling
- [gh!657][gh!657] - Updated documentation for org-rename by @pboling
- More funding links by @Aboling0
- Documentation: Added docs/OIDC.md with OIDC 1.0 overview, example, and references

### Changed

- Upgrade Code of Conduct to Contributor Covenant 2.1 by @pboling
- [gh!660][gh!660] - Shrink post-install message by 4 lines by @pboling

### Fixed

- [gh!660][gh!660] - Links in README (including link to HEAD documentation) by @pboling

### Security

[gh!660]: https://github.com/ruby-oauth/oauth2/pull/660
[gh!657]: https://github.com/ruby-oauth/oauth2/pull/657
[gh!656]: https://github.com/ruby-oauth/oauth2/pull/656

## [2.0.12] - 2025-05-31

- TAG: [v2.0.12][2.0.12t]
- Line Coverage: 100.0% (520 / 520)
- Branch Coverage: 100.0% (174 / 174)
- 80.00% documented

### Added

- [gh!652][gh!652] - Support IETF rfc7515 JSON Web Signature - JWS by @mridang
    - Support JWT `kid` for key discovery and management
- More Documentation by @pboling
    - Documented Serialization Extensions
    - Added Gatzo.com FLOSS logo by @Aboling0, CC BY-SA 4.0
- Documentation site @ https://oauth2.galtzo.com now complete

### Changed

- Updates to gemspec (email, funding url, post install message)

### Fixed

- Documentation Typos by @pboling

[gh!652]: https://github.com/ruby-oauth/oauth2/pull/652

## [2.0.11] - 2025-05-23

- TAG: [v2.0.11][2.0.11t]
- COVERAGE: 100.00% -- 518/518 lines in 14 files
- BRANCH COVERAGE: 100.00% -- 172/172 branches in 14 files
- 80.00% documented

### Added

- [gh!651](https://github.com/ruby-oauth/oauth2/pull/651) - `:snaky_hash_klass` option (@pboling)
- More documentation
- Codeberg as ethical mirror (@pboling)
    - https://codeberg.org/ruby-oauth/oauth2
- Don't check for cert if SKIP_GEM_SIGNING is set (@pboling)
- All runtime deps, including oauth-xx sibling gems, are now tested against HEAD (@pboling)
- All runtime deps, including ruby-oauth sibling gems, are now tested against HEAD (@pboling)
- YARD config, GFM compatible with relative file links (@pboling)
- Documentation site on GitHub Pages (@pboling)
    - [oauth2.galtzo.com](https://oauth2.galtzo.com)
- [!649](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/649) - Test compatibility with all key minor versions of Hashie v0, v1, v2, v3, v4, v5, HEAD (@pboling)
- [gh!651](https://github.com/ruby-oauth/oauth2/pull/651) - Mock OAuth2 server for testing (@pboling)
    - https://github.com/navikt/mock-oauth2-server

### Changed

- [gh!651](https://github.com/ruby-oauth/oauth2/pull/651) - Upgraded to snaky_hash v2.0.3 (@pboling)
    - Provides solution for serialization issues
- Updated `spec.homepage_uri` in gemspec to GitHub Pages YARD documentation site (@pboling)

### Fixed

- [gh!650](https://github.com/ruby-oauth/oauth2/pull/650) - Regression in return type of `OAuth2::Response#parsed` (@pboling)
- Incorrect documentation related to silencing warnings (@pboling)

## [2.0.10] - 2025-05-17

- TAG: [v2.0.10][2.0.10t]
- COVERAGE: 100.00% -- 518/518 lines in 14 files
- BRANCH COVERAGE: 100.00% -- 170/170 branches in 14 files
- 79.05% documented

### Added

- [gh!632](https://github.com/ruby-oauth/oauth2/pull/632) - Added `funding.yml` (@Aboling0)
- [!635](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/635) - Added `.gitlab-ci.yml` (@jessieay)
- [#638](https://gitlab.com/ruby-oauth/oauth2/-/issues/638) - Documentation of support for **ILO Fundamental Principles of Rights at Work** (@pboling)
- [!642](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/642) - 20-year certificate for signing gem releases, expires 2045-04-29 (@pboling)
    - Gemspec metadata
        - funding_uri
        - news_uri
        - mailing_list_uri
    - SHA256 and SHA512 Checksums for release
- [!643](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/643) - Add `token_name` option (@pboling)
    - Specify the parameter name that identifies the access token
- [!645](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/645) - Add `OAuth2::OAUTH_DEBUG` constant, based on `ENV["OAUTH_DEBUG"] (@pboling)
- [!646](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/646) - Add `OAuth2.config.silence_extra_tokens_warning`, default: false (@pboling)
- [!647](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/647) - Add IETF RFC 7009 Token Revocation compliant (@pboling)
    - `OAuth2::Client#revoke_token`
    - `OAuth2::AccessToken#revoke`
    - See: https://datatracker.ietf.org/doc/html/rfc7009
- [gh!644](https://github.com/ruby-oauth/oauth2/pull/644), [gh!645](https://github.com/ruby-oauth/oauth2/pull/645) - Added CITATION.cff (@Aboling0)
- [!648](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/648) - Improved documentation (@pboling)

### Changed

- Default value of `OAuth2.config.silence_extra_tokens_warning` was `false`, now `true` (@pboling)
- Gem releases are now cryptographically signed, with a 20-year cert (@pboling)
    - Allow linux distros to build release without signing, as their package managers sign independently
- [!647](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/647) - `OAuth2::AccessToken#refresh` now supports block param pass through (@pboling)
- [!647](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/647) - `OAuth2.config` is no longer writable (@pboling)
- [!647](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/647) - Errors raised by `OAuth2::AccessToken` are now always `OAuth2::Error` and have better metadata (@pboling)

### Fixed

- [#95](https://gitlab.com/ruby-oauth/oauth2/-/issues/95) - restoring an access token via `AccessToken#from_hash` (@pboling)
    - This was a 13 year old bug report. 😘
- [#619](https://gitlab.com/ruby-oauth/oauth2/-/issues/619) - Internal options (like `snaky`, `raise_errors`, and `parse`) are no longer included in request (@pboling)
- [!633](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/633) - Spaces will now be encoded as `%20` instead of `+` (@nov.matake)
- [!634](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/634) - `CHANGELOG.md` documentation fix (@skuwa229)
- [!638](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/638) - fix `expired?` when `expires_in` is `0` (@disep)
- [!639](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/639) - Only instantiate `OAuth2::Error` if `raise_errors` option is `true` (@glytch2)
- [#639](https://gitlab.com/ruby-oauth/oauth2/-/issues/639) - `AccessToken#to_hash` is now serializable, just a regular Hash (@pboling)
- [!640](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/640) - `README.md` documentation fix (@martinezcoder)
- [!641](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/641) - Do not include sensitive information in the `inspect` (@manuelvanrijn)
- [#641](https://gitlab.com/ruby-oauth/oauth2/-/issues/641) - Made default JSON response parser more resilient (@pboling)
- [#645](https://gitlab.com/ruby-oauth/oauth2/-/issues/645) - Response no longer becomes a snaky hash (@pboling)
- [gh!646](https://github.com/ruby-oauth/oauth2/pull/646) - Change `require` to `require_relative` (improve performance) (@Aboling0)

## [2.0.9] - 2022-09-16

- TAG: [v2.0.9][2.0.9t]

### Added

- More specs (@pboling)

### Changed

- Complete migration to main branch as default (@pboling)
- Complete migration to Gitlab, updating all links, and references in VCS-managed files (@pboling)

## [2.0.8] - 2022-09-01

- TAG: [v2.0.8][2.0.8t]

### Changed

- [!630](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/630) - Extract snaky_hash to external dependency (@pboling)

### Added

- [!631](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/631) - New global configuration option OAuth2.config.silence_extra_tokens_warning (default: false) fixes [#628](https://gitlab.com/ruby-oauth/oauth2/-/issues/628)

## [2.0.7] - 2022-08-22

- TAG: [v2.0.7][2.0.7t]

### Added

- [!629](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/629) - Allow POST of JSON to get token (@pboling, @terracatta)

### Fixed

- [!626](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/626) - Fixes a regression in 2.0.6. Will now prefer the key order from the lookup, not the hash keys (@rickselby)
    - Note: This fixes compatibility with `omniauth-oauth2` and AWS
- [!625](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/625) - Fixes the printed version in the post install message (@hasghari)

## [2.0.6] - 2022-07-13

- TAG: [v2.0.6][2.0.6t]

### Fixed

- [!624](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/624) - Fixes a [regression](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/623) in v2.0.5, where an error would be raised in refresh_token flows due to (legitimate) lack of access_token (@pboling)

## [2.0.5] - 2022-07-07

- TAG: [v2.0.5][2.0.5t]

### Fixed

- [!620](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/620) - Documentation improvements, to help with upgrading (@swanson)
- [!621](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/621) - Fixed [#528](https://gitlab.com/ruby-oauth/oauth2/-/issues/528) and [#619](https://gitlab.com/ruby-oauth/oauth2/-/issues/619) (@pboling)
    - All data in responses is now returned, with the access token removed and set as `token`
        - `refresh_token` is no longer dropped
        - **BREAKING**: Microsoft's `id_token` is no longer left as `access_token['id_token']`, but moved to the standard `access_token.token` that all other strategies use
    - Remove `parse` and `snaky` from options so they don't get included in response
    - There is now 100% test coverage, for lines _and_ branches, and it will stay that way.

## [2.0.4] - 2022-07-01

- TAG: [v2.0.4][2.0.4t]

### Fixed

- [!618](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/618) - In some scenarios the `snaky` option default value was not applied (@pboling)

## [2.0.3] - 2022-06-28

- TAG: [v2.0.3][2.0.3t]

### Added

- [!611](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/611) - Proper deprecation warnings for `extract_access_token` argument (@pboling)
- [!612](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/612) - Add `snaky: false` option to skip conversion to `OAuth2::SnakyHash` (default: true) (@pboling)

### Fixed

- [!608](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/608) - Wrap `Faraday::TimeoutError` in `OAuth2::TimeoutError` (@nbibler)
- [!615](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/615) - Fix support for requests with blocks, see `Faraday::Connection#run_request` (@pboling)

## [2.0.2] - 2022-06-24

- TAG: [v2.0.2][2.0.2t]

### Fixed

- [!604](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/604) - Wrap `Faraday::TimeoutError` in `OAuth2::TimeoutError` (@stanhu)
- [!606](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/606) - Ruby 2.7 deprecation warning fix: Move `access_token_class` parameter into `Client` constructor (@stanhu)
- [!607](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/607) - CHANGELOG correction, reference to `OAuth2::ConnectionError` (@zavan)

## [2.0.1] - 2022-06-22

- TAG: [v2.0.1][2.0.1t]

### Added

- Documentation improvements (@pboling)
- Increased test coverage to 99% (@pboling)

## [2.0.0] - 2022-06-21

- TAG: [v2.0.0][2.0.0t]

### Added

- [!158](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/158), [!344](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/344) - Optionally pass raw response to parsers (@niels)
- [!190](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/190), [!332](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/332), [!334](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/334), [!335](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/335), [!360](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/360), [!426](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/426), [!427](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/427), [!461](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/461) - Documentation (@josephpage, @pboling, @meganemura, @joshRpowell, @elliotcm)
- [!220](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/220) - Support IETF rfc7523 JWT Bearer Tokens Draft 04+ (@jhmoore)
- [!298](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/298) - Set the response object on the access token on Client#get_token for debugging (@cpetschnig)
- [!305](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/305) - Option: `OAuth2::Client#get_token` - `:access_token_class` (`AccessToken`); user specified class to use for all calls to `get_token` (@styd)
- [!346](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/571) - Modern gem structure (@pboling)
- [!351](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/351) - Support Jruby 9k (@pboling)
- [!362](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/362) - Support SemVer release version scheme (@pboling)
- [!363](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/363) - New method `OAuth2::AccessToken#refresh!` same as old `refresh`, with backwards compatibility alias (@pboling)
- [!364](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/364) - Support `application/hal+json` format (@pboling)
- [!365](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/365) - Support `application/vnd.collection+json` format (@pboling)
- [!376](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/376) - _Documentation_: Example / Test for Google 2-legged JWT (@jhmoore)
- [!381](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/381) - Spec for extra header params on client credentials (@nikz)
- [!394](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/394) - Option: `OAuth2::AccessToken#initialize` - `:expires_latency` (`nil`); number of seconds by which AccessToken validity will be reduced to offset latency (@klippx)
- [!412](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/412) - Support `application/vdn.api+json` format (from jsonapi.org) (@david-christensen)
- [!413](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/413) - _Documentation_: License scan and report (@meganemura)
- [!442](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/442) - Option: `OAuth2::Client#initialize` - `:logger` (`::Logger.new($stdout)`) logger to use when OAUTH_DEBUG is enabled (for parity with `1-4-stable` branch) (@rthbound)
- [!494](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/494) - Support [OIDC 1.0 Private Key JWT](https://openid.net/specs/openid-connect-core-1_0.html#ClientAuthentication); based on the OAuth JWT assertion specification [(RFC 7523)](https://tools.ietf.org/html/rfc7523) (@SteveyblamWork)
- [!549](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/549) - Wrap `Faraday::ConnectionFailed` in `OAuth2::ConnectionError` (@nikkypx)
- [!550](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/550) - Raise error if location header not present when redirecting (@stanhu)
- [!552](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/552) - Add missing `version.rb` require (@ahorek)
- [!553](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/553) - Support `application/problem+json` format (@janz93)
- [!560](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/560) - Support IETF rfc6749, section 2.3.1 - don't set auth params when `nil` (@bouk)
- [!571](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/571) - Support Ruby 3.1 (@pboling)
- [!575](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/575) - Support IETF rfc7231, section 7.1.2 - relative location in redirect (@pboling)
- [!581](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/581) - _Documentation_: of breaking changes (@pboling)

### Changed

- [!191](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/191) - **BREAKING**: Token is expired if `expired_at` time is `now` (@davestevens)
- [!312](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/312) - **BREAKING**: Set `:basic_auth` as default for `:auth_scheme` instead of `:request_body`. This was default behavior before 1.3.0. (@tetsuya, @wy193777)
- [!317](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/317) - _Dependency_: Upgrade `jwt` to 2.x.x (@travisofthenorth)
- [!338](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/338) - _Dependency_: Switch from `Rack::Utils.escape` to `CGI.escape` (@josephpage)
- [!339](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/339), [!368](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/368), [!424](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/424), [!479](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/479), [!493](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/493), [!539](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/539), [!542](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/542), [!553](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/553) - CI Updates, code coverage, linting, spelling, type fixes, New VERSION constant (@pboling, @josephpage, @ahorek)
- [!410](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/410) - **BREAKING**: Removed the ability to call .error from an OAuth2::Response object (@jhmoore)
- [!414](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/414) - Use Base64.strict_encode64 instead of custom internal logic (@meganemura)
- [!469](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/469) - **BREAKING**: Default value for option `OAuth2::Client` - `:authorize_url` removed leading slash to work with relative paths by default (`'oauth/authorize'`) (@ghost)
- [!469](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/469) - **BREAKING**: Default value for option `OAuth2::Client` - `:token_url` removed leading slash to work with relative paths by default (`'oauth/token'`) (@ghost)
- [!507](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/507), [!575](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/575) - **BREAKING**: Transform keys to snake case, always, by default (ultimately via `rash_alt` gem)
    - Original keys will still work as previously, in most scenarios, thanks to `rash_alt` gem.
    - However, this is a _breaking_ change if you rely on `response.parsed.to_h`, as the keys in the result will be snake case.
    - As of version 2.0.4 you can turn key transformation off with the `snaky: false` option.
- [!576](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/576) - **BREAKING**: Stop rescuing parsing errors (@pboling)
- [!591](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/576) - _DEPRECATION_: `OAuth2::Client` - `:extract_access_token` option is deprecated

### Fixed

- [!158](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/158), [!344](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/344) - Handling of errors when using `omniauth-facebook` (@niels)
- [!294](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/294) - Fix: "Unexpected middleware set" issue with Faraday when `OAUTH_DEBUG=true` (@spectator, @gafrom)
- [!300](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/300) - _Documentation_: `Oauth2::Error` - Error codes are strings, not symbols (@NobodysNightmare)
- [!318](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/318), [!326](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/326), [!343](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/343), [!347](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/347), [!397](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/397), [!464](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/464), [!561](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/561), [!565](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/565) - _Dependency_: Support all versions of `faraday` (see [gemfiles/README.md][gemfiles/readme] for compatibility matrix with Ruby engines & versions) (@pboling, @raimondasv, @zacharywelch, @Fudoshiki, @ryogift, @sj26, @jdelStrother)
- [!322](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/322), [!331](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/331), [!337](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/337), [!361](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/361), [!371](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/371), [!377](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/377), [!383](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/383), [!392](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/392), [!395](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/395), [!400](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/400), [!401](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/401), [!403](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/403), [!415](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/415), [!567](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/567) - Updated Rubocop, Rubocop plugins and improved code style (@pboling, @bquorning, @lautis, @spectator)
- [!328](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/328) - _Documentation_: Homepage URL is SSL (@amatsuda)
- [!339](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/339), [!479](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/479) - Update testing infrastructure for all supported Rubies (@pboling and @josephpage)
- [!366](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/366) - **Security**: Fix logging to `$stdout` of request and response bodies via Faraday's logger and `ENV["OAUTH_DEBUG"] == 'true'` (@pboling)
- [!380](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/380) - Fix: Stop attempting to encode non-encodable objects in `Oauth2::Error` (@jhmoore)
- [!399](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/399) - Fix: Stop duplicating `redirect_uri` in `get_token` (@markus)
- [!410](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/410) - Fix: `SystemStackError` caused by circular reference between Error and Response classes (@jhmoore)
- [!460](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/460) - Fix: Stop throwing errors when `raise_errors` is set to `false`; analog of [!524](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/524) for `1-4-stable` branch (@joaolrpaulo)
- [!472](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/472) - **Security**: Add checks to enforce `client_secret` is *never* passed in authorize_url query params for `implicit` and `auth_code` grant types (@dfockler)
- [!482](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/482) - _Documentation_: Update last of `intridea` links to `ruby-oauth` (@pboling)
- [!536](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/536) - **Security**: Compatibility with more (and recent) Ruby OpenSSL versions, Github Actions, Rubocop updated, analogous to [!535](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/535) on `1-4-stable` branch (@pboling)
- [!595](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/595) - Graceful handling of empty responses from `Client#get_token`, respecting `:raise_errors` config (@stanhu)
- [!596](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/596) - Consistency between `AccessToken#refresh` and `Client#get_token` named arguments (@stanhu)
- [!598](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/598) - Fix unparseable data not raised as error in `Client#get_token`, respecting `:raise_errors` config (@stanhu)

### Removed

- [!341](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/341) - Remove Rdoc & Jeweler related files (@josephpage)
- [!342](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/342) - **BREAKING**: Dropped support for Ruby 1.8 (@josephpage)
- [!539](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/539) - Remove reliance on globally included OAuth2 in tests, analog of [!538](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/538) for 1-4-stable (@anderscarling)
- [!566](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/566) - _Dependency_: Removed `wwtd` (@bquorning)
- [!589](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/589), [!593](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/593) - Remove support for expired MAC token draft spec (@stanhu)
- [!590](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/590) - _Dependency_: Removed `multi_json` (@stanhu)

## [1.4.11] - 2022-09-16

- TAG: [v1.4.11][1.4.11t]
- Complete migration to main branch as default (@pboling)
- Complete migration to Gitlab, updating all links, and references in VCS-managed files (@pboling)

## [1.4.10] - 2022-07-01

- TAG: [v1.4.10][1.4.10t]
- FIPS Compatibility [!587](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/587) (@akostadinov)

## [1.4.9] - 2022-02-20

- TAG: [v1.4.9][1.4.9t]
- Fixes compatibility with Faraday v2 [572](https://gitlab.com/ruby-oauth/oauth2/-/issues/572)
- Includes supported versions of Faraday in test matrix:
    - Faraday ~> 2.2.0 with Ruby >= 2.6
    - Faraday ~> 1.10 with Ruby >= 2.4
    - Faraday ~> 0.17.3 with Ruby >= 1.9
- Add Windows and MacOS to test matrix

## [1.4.8] - 2022-02-18

- TAG: [v1.4.8][1.4.8t]
- MFA is now required to push new gem versions (@pboling)
- README overhaul w/ new Ruby Version and Engine compatibility policies (@pboling)
- [!569](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/569) Backport fixes ([!561](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/561) by @ryogift), and add more fixes, to allow faraday 1.x and 2.x (@jrochkind)
- Improve Code Coverage tracking (Coveralls, CodeCov, CodeClimate), and enable branch coverage (@pboling)
- Add CodeQL, Security Policy, Funding info (@pboling)
- Added Ruby 3.1, jruby, jruby-head, truffleruby, truffleruby-head to build matrix (@pboling)
- [!543](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/543) - Support for more modern Open SSL libraries (@pboling)

## [1.4.7] - 2021-03-19

- TAG: [v1.4.7][1.4.7t]
- [!541](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/541) - Backport fix to expires_at handling [!533](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/533) to 1-4-stable branch. (@dobon)

## [1.4.6] - 2021-03-19

- TAG: [v1.4.6][1.4.6t]
- [!540](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/540) - Add VERSION constant (@pboling)
- [!537](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/537) - Fix crash in OAuth2::Client#get_token (@anderscarling)
- [!538](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/538) - Remove reliance on globally included OAuth2 in tests, analogous to [!539](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/539) on main branch (@anderscarling)

## [1.4.5] - 2021-03-18

- TAG: [v1.4.5][1.4.5t]
- [!535](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/535) - Compatibility with range of supported Ruby OpenSSL versions, Rubocop updates, Github Actions, analogous to [!536](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/536) on main branch (@pboling)
- [!518](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/518) - Add extract_access_token option to OAuth2::Client (@jonspalmer)
- [!507](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/507) - Fix camel case content type, response keys (@anvox)
- [!500](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/500) - Fix YARD documentation formatting (@olleolleolle)

## [1.4.4] - 2020-02-12

- TAG: [v1.4.4][1.4.4t]
- [!408](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/408) - Fixed expires_at for formatted time (@Lomey)

## [1.4.3] - 2020-01-29

- TAG: [v1.4.3][1.4.3t]
- [!483](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/483) - add project metadata to gemspec (@orien)
- [!495](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/495) - support additional types of access token requests (@SteveyblamFreeagent, @thomcorley, @dgholz)
    - Adds support for private_key_jwt and tls_client_auth
- [!433](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/433) - allow field names with square brackets and numbers in params (@asm256)

## [1.4.2] - 2019-10-01

- TAG: [v1.4.2][1.4.2t]
- [!478](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/478) - support latest version of faraday & fix build (@pboling)
    - Officially support Ruby 2.6 and truffleruby

## [1.4.1] - 2018-10-13

- TAG: [v1.4.1][1.4.1t]
- [!417](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/417) - update jwt dependency (@thewoolleyman)
- [!419](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/419) - remove rubocop dependency (temporary, added back in [!423](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/423)) (@pboling)
- [!418](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/418) - update faraday dependency (@pboling)
- [!420](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/420) - update [oauth2.gemspec](https://gitlab.com/ruby-oauth/oauth2/-/blob/1-4-stable/oauth2.gemspec) (@pboling)
- [!421](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/421) - fix [CHANGELOG.md](https://gitlab.com/ruby-oauth/oauth2/-/blob/1-4-stable/CHANGELOG.md) for previous releases (@pboling)
- [!422](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/422) - update [LICENSE](https://gitlab.com/ruby-oauth/oauth2/-/blob/1-4-stable/LICENSE) and [README.md](https://gitlab.com/ruby-oauth/oauth2/-/blob/1-4-stable/README.md) (@pboling)
- [!423](https://gitlab.com/ruby-oauth/oauth2/-/merge_requests/423) - update [builds](https://travis-ci.org/ruby-oauth/oauth2/builds), [Rakefile](https://gitlab.com/ruby-oauth/oauth2/-/blob/1-4-stable/Rakefile) (@pboling)
    - officially document supported Rubies
        * Ruby 1.9.3
        * Ruby 2.0.0
        * Ruby 2.1
        * Ruby 2.2
        * [JRuby 1.7][jruby-1.7] (targets MRI v1.9)
        * [JRuby 9.0][jruby-9.0] (targets MRI v2.0)
        * Ruby 2.3
        * Ruby 2.4
        * Ruby 2.5
        * [JRuby 9.1][jruby-9.1] (targets MRI v2.3)
        * [JRuby 9.2][jruby-9.2] (targets MRI v2.5)

[jruby-1.7]: https://www.jruby.org/2017/05/11/jruby-1-7-27.html
[jruby-9.0]: https://www.jruby.org/2016/01/26/jruby-9-0-5-0.html
[jruby-9.1]: https://www.jruby.org/2017/05/16/jruby-9-1-9-0.html
[jruby-9.2]: https://www.jruby.org/2018/05/24/jruby-9-2-0-0.html

## [1.4.0] - 2017-06-09

- TAG: [v1.4.0][1.4.0t]
- Drop Ruby 1.8.7 support (@sferik)
- Fix some RuboCop offenses (@sferik)
- _Dependency_: Remove Yardstick (@sferik)
- _Dependency_: Upgrade Faraday to 0.12 (@sferik)

## [1.3.1] - 2017-03-03

- TAG: [v1.3.1][1.3.1t]
- Add support for Ruby 2.4.0 (@pschambacher)
- _Dependency_: Upgrade Faraday to Faraday 0.11 (@mcfiredrill, @rhymes, @pschambacher)

## [1.3.0] - 2016-12-28

- TAG: [v1.3.0][1.3.0t]
- Add support for header-based authentication to the `Client` so it can be used across the library (@bjeanes)
- Default to header-based authentication when getting a token from an authorisation code (@maletor)
- **Breaking**: Allow an `auth_scheme` (`:basic_auth` or `:request_body`) to be set on the client, defaulting to `:request_body` to maintain backwards compatibility (@maletor, @bjeanes)
- Handle `redirect_uri` according to the OAuth 2 spec, so it is passed on redirect and at the point of token exchange (@bjeanes)
- Refactor handling of encoding of error responses (@urkle)
- Avoid instantiating an `Error` if there is no error to raise (@urkle)
- Add support for Faraday 0.10 (@rhymes)

## [1.2.0] - 2016-07-01

- TAG: [v1.2.0][1.2.0t]
- Properly handle encoding of error responses (so we don't blow up, for example, when Google's response includes a ∞) (@Motoshi-Nishihira)
- Make a copy of the options hash in `AccessToken#from_hash` to avoid accidental mutations (@Linuus)
- Use `raise` rather than `fail` to throw exceptions (@sferik)

## [1.1.0] - 2016-01-30

- TAG: [v1.1.0][1.1.0t]
- Various refactors (eliminating `Hash#merge!` usage in `AccessToken#refresh!`, use `yield` instead of `#call`, freezing mutable objects in constants, replacing constants with class variables) (@sferik)
- Add support for Rack 2, and bump various other dependencies (@sferik)

## [1.0.0] - 2014-07-09

- TAG: [v1.0.0][1.0.0t]

### Added

- Add an implementation of the MAC token spec.

### Fixed

- Fix Base64.strict_encode64 incompatibility with Ruby 1.8.7.

## [0.5.0] - 2011-07-29

- TAG: [v0.5.0][0.5.0t]

### Changed

- *breaking* `oauth_token` renamed to `oauth_bearer`.
- *breaking* `authorize_path` Client option renamed to `authorize_url`.
- *breaking* `access_token_path` Client option renamed to `token_url`.
- *breaking* `access_token_method` Client option renamed to `token_method`.
- *breaking* `web_server` renamed to `auth_code`.

## [0.4.1] - 2011-04-20

- TAG: [v0.4.1][0.4.1t]

## [0.4.0] - 2011-04-20

- TAG: [v0.4.0][0.4.0t]

## [0.3.0] - 2011-04-08

- TAG: [v0.3.0][0.3.0t]

## [0.2.0] - 2011-04-01

- TAG: [v0.2.0][0.2.0t]

## [0.1.1] - 2011-01-12

- TAG: [v0.1.1][0.1.1t]

## [0.1.0] - 2010-10-13

- TAG: [v0.1.0][0.1.0t]

## [0.0.13] - 2010-08-17

- TAG: [v0.0.13][0.0.13t]

## [0.0.12] - 2010-08-17

- TAG: [v0.0.12][0.0.12t]

## [0.0.11] - 2010-08-17

- TAG: [v0.0.11][0.0.11t]

## [0.0.10] - 2010-06-19

- TAG: [v0.0.10][0.0.10t]

## [0.0.9] - 2010-06-18

- TAG: [v0.0.9][0.0.9t]

## [0.0.8] - 2010-04-27

- TAG: [v0.0.8][0.0.8t]

## [0.0.7] - 2010-04-27

- TAG: [v0.0.7][0.0.7t]

## [0.0.6] - 2010-04-25

- TAG: [v0.0.6][0.0.6t]

## [0.0.5] - 2010-04-23

- TAG: [v0.0.5][0.0.5t]

## [0.0.4] - 2010-04-22

- TAG: [v0.0.4][0.0.4t]

## [0.0.3] - 2010-04-22

- TAG: [v0.0.3][0.0.3t]

## [0.0.2] - 2010-04-22

- TAG: [v0.0.2][0.0.2t]

## [0.0.1] - 2010-04-22

- TAG: [v0.0.1][0.0.1t]

[gemfiles/readme]: gemfiles/README.md

[Unreleased]: https://github.com/ruby-oauth/oauth2/compare/v2.0.18...HEAD
[2.0.18]: https://github.com/ruby-oauth/oauth2/compare/v2.0.17...v2.0.18
[2.0.18t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.18
[2.0.17]: https://github.com/ruby-oauth/oauth2/compare/v2.0.16...v2.0.17
[2.0.17t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.17
[2.0.16]: https://github.com/ruby-oauth/oauth2/compare/v2.0.15...v2.0.16
[2.0.16t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.16
[2.0.15]: https://github.com/ruby-oauth/oauth2/compare/v2.0.14...v2.0.15
[2.0.15t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.15
[2.0.14]: https://github.com/ruby-oauth/oauth2/compare/v2.0.13...v2.0.14
[2.0.14t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.14
[2.0.13]: https://github.com/ruby-oauth/oauth2/compare/v2.0.12...v2.0.13
[2.0.13t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.13
[2.0.12]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v2.0.11...v2.0.12
[2.0.12t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.12
[2.0.11]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v2.0.10...v2.0.11
[2.0.11t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.11
[2.0.10]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v2.0.9...v2.0.10
[2.0.10t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.10
[2.0.9]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v2.0.8...v2.0.9
[2.0.9t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.9
[2.0.8]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v2.0.7...v2.0.8
[2.0.8t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.8
[2.0.7]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v2.0.6...v2.0.7
[2.0.7t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.7
[2.0.6]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v2.0.5...v2.0.6
[2.0.6t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.6
[2.0.5]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v2.0.4...v2.0.5
[2.0.5t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.5
[2.0.4]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v2.0.3...v2.0.4
[2.0.4t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.4
[2.0.3]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v2.0.2...v2.0.3
[2.0.3t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.3
[2.0.2]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v2.0.1...v2.0.2
[2.0.2t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.2
[2.0.1]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v2.0.0...v2.0.1
[2.0.1t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.1
[2.0.0]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.4.11...v2.0.0
[2.0.0t]: https://github.com/ruby-oauth/oauth2/releases/tag/v2.0.0
[1.4.11]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.4.10...v1.4.11
[1.4.11t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.4.11
[1.4.10]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.4.9...v1.4.10
[1.4.10t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.4.10
[1.4.9]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.4.8...v1.4.9
[1.4.9t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.4.9
[1.4.8]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.4.7...v1.4.8
[1.4.8t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.4.8
[1.4.7]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.4.6...v1.4.7
[1.4.7t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.4.7
[1.4.6]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.4.5...v1.4.6
[1.4.6t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.4.6
[1.4.5]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.4.4...v1.4.5
[1.4.5t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.4.5
[1.4.4]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.4.3...v1.4.4
[1.4.4t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.4.4
[1.4.3]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.4.2...v1.4.3
[1.4.3t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.4.3
[1.4.2]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.4.1...v1.4.2
[1.4.2t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.4.2
[1.4.1]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.4.0...v1.4.1
[1.4.1t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.4.1
[1.4.0]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.3.1...v1.4.0
[1.4.0t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.4.0
[1.3.1]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.3.0...v1.3.1
[1.3.1t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.3.1
[1.3.0]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.2.0...v1.3.0
[1.3.0t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.3.0
[1.2.0]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.1.0...v1.2.0
[1.2.0t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.2.0
[1.1.0]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v1.0.0...v1.1.0
[1.1.0t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.1.0
[1.0.0]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.9.4...v1.0.0
[1.0.0t]: https://github.com/ruby-oauth/oauth2/releases/tag/v1.0.0
[0.5.0]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.4.1...v0.5.0
[0.5.0t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.5.0
[0.4.1]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.4.0...v0.4.1
[0.4.1t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.4.1
[0.4.0]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.3.0...v0.4.0
[0.4.0t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.4.0
[0.3.0]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.2.0...v0.3.0
[0.3.0t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.3.0
[0.2.0]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.1.1...v0.2.0
[0.2.0t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.2.0
[0.1.1]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.1.0...v0.1.1
[0.1.1t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.1.1
[0.1.0]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.13...v0.1.0
[0.1.0t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.1.0
[0.0.13]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.12...v0.0.13
[0.0.13t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.13
[0.0.12]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.11...v0.0.12
[0.0.12t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.12
[0.0.11]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.10...v0.0.11
[0.0.11t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.11
[0.0.10]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.9...v0.0.10
[0.0.10t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.10
[0.0.9]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.8...v0.0.9
[0.0.9t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.9
[0.0.8]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.7...v0.0.8
[0.0.8t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.8
[0.0.7]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.6...v0.0.7
[0.0.7t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.7
[0.0.6]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.5...v0.0.6
[0.0.6t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.6
[0.0.5]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.4...v0.0.5
[0.0.5t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.5
[0.0.4]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.3...v0.0.4
[0.0.4t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.4
[0.0.3]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.2...v0.0.3
[0.0.3t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.3
[0.0.2]: https://gitlab.com/ruby-oauth/oauth2/-/compare/v0.0.1...v0.0.2
[0.0.2t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.2
[0.0.1]: https://github.com/ruby-oauth/oauth2/compare/311d9f4...v0.0.1
[0.0.1t]: https://github.com/ruby-oauth/oauth2/releases/tag/v0.0.1
