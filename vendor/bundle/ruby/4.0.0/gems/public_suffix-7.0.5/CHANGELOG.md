# Changelog


## 7.0.5 - 2026-03-03

### Fixed

- Fix release crash caused by unconditional rubocop/yard requires in Rakefile.


## 7.0.4 - 2026-03-03

### Fixed

- Fix release workflow.


## 7.0.3 - 2026-03-03

### Changed

- Updated definitions.


## 7.0.2 - 2026-01-04

### Changed

- Excluded symlinks and unnecessary files from gem packaging. On Windows symlinks cannot be created without Administrator privileges or with developer mode enabled #496.


## 7.0.1 - 2026-01-03

### Changed

- Updated definitions.


## 7.0.0 - 2024-11-17

### Changed

- Updated definitions.
- Minimum Ruby version is 3.2


## 6.0.2 - 2024-04-30

### Changed

- Updated definitions.


## 6.0.1 - 2024-07-23

### Changed

- Updated definitions.


## 6.0.0 - 2024-06-17

Same as 5.1.0. Re-releasing as a major version change due to a major ruby version requirement change.

### Changed

- Updated definitions.
- Minimum Ruby version is 3.0


## 5.1.1 - 2024-06-17

No significant changes. Releasing a mini version to address 5.1.0 release with major ruby requirement change #315.


## 5.1.0 - 2024-06-15

### Changed

- Updated definitions.
- Minimum Ruby version is 3.0


## 5.0.5 - 2024-04-02

### Changed

- Updated definitions.


## 5.0.4 - 2023-11-17

### Changed

- Reduced .gem file size #258. (Thanks @ybiquitous)
- Updated definitions.


## 5.0.3 - 2023-07-11

### Fixed

- Fixed automated release workflow.


## 5.0.2 - 2023-07-11

### Changed

- Updated definitions.


## 5.0.1 - 2022-12-07

### Changed

- Updated definitions.


## 5.0.0 - 2022-07-24

### Changed

- Minimum Ruby version is 2.6
- Updated definitions.


## 4.0.7 - 2022-04-12

### Fixed

- Fixed YARD rake task #179

### Changed

- Updated definitions.


## 4.0.6 - 2020-09-02

### Changed

- Updated definitions.


## 4.0.5 - 2020-05-09

### Changed

- Updated definitions.


## 4.0.4 - 2020-04-05

### Changed

- Updated definitions.


## 4.0.3 - 2020-01-05

### Fixed

- Fixed 2.7 deprecations and warnings #167. (Thanks @BrianHawley)


## 4.0.2 - 2019-12-27

### Changed

- Updated definitions.


## 4.0.1 - 2019-08-09

### Changed

- Updated definitions.


## 4.0.0 - 2019-06-25

### Changed

- Minimum Ruby version is 2.3


## 3.1.1 - 2019-06-25

IMPORTANT: 3.x is the latest version compatible with Ruby 2.1 and Ruby 2.2.

### Changed

- Updated definitions.
- Rolled back support for Ruby 2.3 #161, #162


## 3.1.0 - 2019-05-27

### Changed

- Updated definitions.
- Minimum Ruby version is 2.3
- Upgraded to Bundler 2.x


## 3.0.3 - 2018-08-15

### Changed

- Updated definitions.


## 3.0.2 - 2018-02-12

### Changed

- Updated definitions.


## 3.0.1 - 2017-11-08

### Changed

- Updated definitions.
- Improve performance and avoid allocation #146. (Thanks @robholland)


## 3.0.0 - 2017-08-04

This new version includes a major redesign of the library internals, with the goal to drastically improve the lookup time while reducing storage space.

For this reason, several public methods that are no longer applicable have been deprecated and/or removed. You can find more information at #133.

### Changed

- Updated definitions.
- Dropped support for Ruby < 2.1
- `PublicSuffix::List#rules` is now protected. You should not rely on it as the internal rule representation is subject to change to optimize performances.
- Removed `PublicSuffix::List.clear`, it was an unnecessary accessor method. Use `PublicSuffix::List.default = nil` if you **really** need to reset the default list. You shouldn't.
- `PublicSuffix::List#select` is now private. You should not use it, instead use `PublicSuffix::List#find`.
- `PublicSuffix::List` no longer implements Enumerable. Instead, use `#each` to loop over, or get an Enumerator.
- Redesigned internal list storage and lookup algorithm to achieve O(1) lookup time (see #133).


## 2.0.5 - 2017-01-02

### Changed

- Updated definitions.
- Initialization performance improvements #128. (Thanks @casperisfine)


## 2.0.4 - 2016-11-07

### Fixed

- Fixed a bug that caused the GEM to be published with the wrong version number in the gemspec #121.

### Changed

- Updated definitions.


## 2.0.3 - 2016-09-30

### Changed

- Updated definitions.


## 2.0.2 - 2016-06-10

### Changed

- Updated definitions.


## 2.0.1 - 2016-05-22

### Fixed

- Fix bug that prevented .valid? to reset the default rule


## 2.0.0 - 2016-05-20

### Added

- Added PublicSuffix.domain # => sld.tld
- Added the ability to disable the use of private domains either at runtime, in addition to the ability to not load the private domains section when reading the list (`private_domains: false`). This feature also superseded the `private_domains` class-level attribute, that is no longer available.

### Changed

- Considerable performance improvements #92
- Updated definitions.
- Removed deprecated PublicSuffix::InvalidDomain exception
- If the suffix is now listed, then the prevaling rule is "*" as defined by the PSL algorithm #91
- Input validation is performed only if you call `PublicSuffix.parse` or `PublicSuffix.list`
- Input with leading dot is invalid per PSL acceptance tests
- Removed `private_domains` class-level attribute. It is replaced by the `private_domains: false` option in the list parse method.
- The default list now assumes you use UTF-8 for reading the input #94,

### Removed

- Removed futile utility helpers such as `Domain#rule`, `Domain#is_a_domain?`, `Domain#is_a_subdomain?`, `Domain#valid?`. You can easily obtain the same result by having a custom method that reconstructs the logic, and/or calling `PublicSuffix.{domain|parse}(domain.to_s)`.


## 1.5.3 - 2015-12-14

### Fixed

- Don't duplicate rule indices when creating index #77. (Thanks @ags)

### Changed

- Updated definitions.


## 1.5.2 - 2015-10-27

### Changed

- Updated definitions.


## 1.5.1 - 2015-04-10

### Fixed

- Ignore case for parsing and validating #62

### Changed

- Updated definitions.


## 1.5.0 - 2015-03-24

### Changed

- Dropped support for Ruby < 2.0
- Updated definitions.


## 1.4.6 - 2014-09-10

### Changed

- Updated definitions.


## 1.4.5 - 2014-08-18

### Changed

- Updated definitions.


## 1.4.4 - 2014-06-17

### Changed

- Updated definitions.


## 1.4.3 - 2014-06-12

### Changed

- Updated definitions.


## 1.4.2 - 2014-03-10

### Changed

- Updated definitions.


## 1.4.1 - 2014-03-07

### Changed

- Updated definitions.


## 1.4.0 - 2014-02-01

### Changed

- Moved the definitions in the lib folder.
- Updated definitions.


## 1.3.3 - 2013-12-01

### Changed

- Updated definitions.


## 1.3.2 - 2013-11-11

### Changed

- Updated definitions.


## 1.3.1 - 2013-08-09

### Changed

- Updated definitions.


## 1.3.0 - 2013-04-03

### Added

- Ability to skip Private Domains #28. (Thanks @rb2k)

### Changed

- Updated definitions.


## 1.2.1 - 2013-03-26

### Changed

- Updated definitions.


## 1.2.0 - 2012-12-24

### Added

- Allow a custom List on `PublicSuffix.parse` #26. (Thanks @itspriddle)

### Fixed

- PublicSuffix.parse and PublicSuffix.valid? crashes when input is nil #20.

### Changed

- Updated definitions.


## 1.1.3 - 2012-09-17

### Changed

- Updated definitions.


## 1.1.2 - 2012-09-03

### Changed

- Updated definitions.


## 1.1.1 - 2012-06-26

### Changed

- Updated definitions.


## 1.1.0 - 2012-03-16

### Fixed

- #valid? and #parse consider URIs as valid domains #15

### Changed

- Updated definitions.
- Removed deprecatd PublicSuffixService::RuleList.


## 1.0.0 - 2011-12-24

### Changed

- Updated definitions.


## 1.0.0.rc1 - 2011-12-24

The library is now known as PublicSuffix.


## 0.9.1 - 2011-12-24

### Changed

- Renamed PublicSuffixService::RuleList to PublicSuffixService::List.
- Renamed PublicSuffixService::List#list to PublicSuffixService::List#rules.
- Renamed PublicSuffixService to PublicSuffix.
- Updated definitions.


## 0.9.0 - 2011-06-17

### Changed

- Minimum Ruby version increased to Ruby 1.8.7.
- rake/gempackagetask is deprecated.  Use rubygems/package_task instead.


## 0.8.4 - 2011-06-17

### Fixed

- Reverted bugfix for issue #12 for Ruby 1.8.6. This is the latest version compatible with Ruby 1.8.6.


## 0.8.3 - 2011-05-27

### Fixed

- Fixed ArgumentError: invalid byte sequence in US-ASCII with Ruby 1.9.2 (#12).

### Changed

- Updated definitions (#11).
- Renamed definitions.txt to definitions.dat.


## 0.8.2 - 2011-03-11

### Added

- Added support for rubygems-test.

### Changed

- Integrated Bundler.
- Updated definitions.


## 0.8.1 - 2010-12-07

### Fixed

- The files in the release 0.8.0 have wrong permission 600 and can't be loaded #10.


## 0.8.0 - 2010-12-05

### Added

- Add support for Fully Qualified Domain Names #7

### Changed

- Update public suffix list to d1a5599b49fa 2010-10-25 15:10 +0100 #9


## 0.7.0 - 2010-10-09

### Fixed

- RuleList cache is not recreated when a new rule is appended to the list #6
- PublicSuffixService.valid? should return false if the domain is not defined or not allowed #4, #5

### Changed

- Using YARD to document the code instead of RDoc.


## 0.6.0 - 2010-09-18

### Added

- PublicSuffixService.parse raises DomainNotAllowed when trying to parse a domain name which exists, but is not allowed by the current definition list #3

        PublicSuffixService.parse("nic.do")
        # => PublicSuffixService::DomainNotAllowed

### Changed

- Renamed PublicSuffixService::InvalidDomain to PublicSuffixService::DomainInvalid


## 0.5.2 - 2010-09-17

### Changed

- Update public suffix list to 248ea690d671 2010-09-16 18:02 +0100


## 0.5.1 - 2010-09-15

### Changed

- Update public suffix list to 14dc66dd53c1 2010-09-15 17:09 +0100


## 0.5.0 - 2010-09-13

### Changed

- Improve documentation for Domain#domain and Domain#subdomain #1.
- Performance improvements #2.


## 0.4.0 - 2010-05-31

### Changed

- Rename library from DomainName to PublicSuffixService to reduce the probability of name conflicts.


## 0.3.1 - 2010-05-31

### Changed

- Deprecated DomainName library.


## 0.3.0 - 2010-05-31

### Changed

- DomainName#domain and DomainName#subdomain are no longer alias of Domain#sld and Domain#tld.
- Removed DomainName#labels and decoupled Rule from DomainName.
- DomainName#valid? no longer instantiates new DomainName objects. This means less overhead.
- Refactoring the entire DomainName API. Removed the internal on-the-fly parsing. Added a bunch of new methods to check and validate the DomainName.


## 0.2.0 - 2010-05-31

### Added

- DomainName#valid?
- DomainName#parse and DomainName#parse!
- DomainName#valid_domain? and DomainName#valid_subdomain?

### Changed

- Make sure RuleList lookup is only performed once.


## 0.1.0 - 2010-05-31

- Initial version
