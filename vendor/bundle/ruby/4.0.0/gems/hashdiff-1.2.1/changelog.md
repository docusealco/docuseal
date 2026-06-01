# Change Log

## v1.2.1 2025-09-06

* Use HTTPS for the source in the Gemfile [#101](https://github.com/liufengyun/hashdiff/issues/101) ([@krzysiek1507](https://github.com/krzysiek1507))

## v1.2.0 2025-5-20

* Added :preserve_key_order option to maintain original hash key order [#99](https://github.com/liufengyun/hashdiff/issues/99) ([@robkiessling](https://github.com/robkiessling))

## v1.1.2 2024-11-12

* Fix bundler cache [#96](https://github.com/liufengyun/hashdiff/issues/96) ([@olleolleolle](https://github.com/olleolleolle))
* Quote the '3.0' in YAML [#95](https://github.com/liufengyun/hashdiff/issues/95) ([@olleolleolle](https://github.com/olleolleolle))
* Fix version in source code [#97](https://github.com/liufengyun/hashdiff/issues/97) ([@liufengyun](https://github.com/liufengyun))

## v1.1.1 2024-08-02

* Fix bug in ignore_keys option [#88](https://github.com/liufengyun/hashdiff/issues/88) ([@Matzfan](https://github.com/Matzfan))
* Exclude spec files from gem package [#94](https://github.com/liufengyun/hashdiff/issues/94) ([@amatsuda](https://github.com/amatsuda))

## v1.1.0 2023-12-14

* Add ignore_keys option ([#86](https://github.com/liufengyun/hashdiff/issues/86) [@Matzfan](https://github.com/Matzfan))
* Remove pinned version of rake < 11
* Bump rspec dep ~> 3.5
* Bump rubocop dep >= 1.52.1
* Bump rubocop-rspec dep > 1.16.0

## v1.0.1 2020-02-25

* Add indifferent option

## v1.0.0 2019-06-06

* Fix typo in readme ([#72](https://github.com/liufengyun/hashdiff/issues/72) [@koic](https://github.com/koic))
* Fix Rubocop offence ([#73](https://github.com/liufengyun/hashdiff/issues/73) [@koic](https://github.com/koic))
* Bumps version to v1.0.0 ([#74](https://github.com/liufengyun/hashdiff/issues/74) [@jfelchner](https://github.com/jfelchner))

## v1.0.0.beta1 2019-06-06

* fix warnings in ci ([#69](https://github.com/liufengyun/hashdiff/issues/69) [@y-yagi](https://github.com/y-yagi))
* drop warnings of the constant change ([#70](https://github.com/liufengyun/hashdiff/issues/70) [@jfelchner](https://github.com/jfelchner))

## v0.4.0 2019-05-28

* refactoring ([#56](https://github.com/liufengyun/hashdiff/issues/56) [#57](https://github.com/liufengyun/hashdiff/issues/57) [#59](https://github.com/liufengyun/hashdiff/issues/59) [#61](https://github.com/liufengyun/hashdiff/issues/61) [@krzysiek1507](https://github.com/krzysiek1507))
* fix typo in README ([#64](https://github.com/liufengyun/hashdiff/issues/64) [@pboling](https://github.com/pboling))
* change HashDiff to Hashdiff ([#65](https://github.com/liufengyun/hashdiff/issues/65) [@jfelchner](https://github.com/jfelchner))

## v0.3.9 2019-04-22

* Performance tweak (thanks [@krzysiek1507](https://github.com/krzysiek1507): [#51](https://github.com/liufengyun/hashdiff/issues/51) [#52](https://github.com/liufengyun/hashdiff/issues/52) [#53](https://github.com/liufengyun/hashdiff/issues/53))

## v0.3.8 2018-12-30

* Add Rubocop and drops Ruby 1.9 support [#47](https://github.com/liufengyun/hashdiff/issues/47)

## v0.3.7 2017-10-08

* remove 1.8.7 support from gemspec [#39](https://github.com/liufengyun/hashdiff/issues/39)

## v0.3.6 2017-08-22

* add option `use_lcs` [#35](https://github.com/liufengyun/hashdiff/issues/35)

## v0.3.5 2017-08-06

* add option `array_path` [#34](https://github.com/liufengyun/hashdiff/issues/34)

## v0.3.4 2017-05-01

* performance improvement of `#similar?` [#31](https://github.com/liufengyun/hashdiff/issues/31)

## v0.3.2 2016-12-27

* replace `Fixnum` by `Integer` [#28](https://github.com/liufengyun/hashdiff/issues/28)

## v0.3.1 2016-11-24

* fix an error when a hash has mixed types [#26](https://github.com/liufengyun/hashdiff/issues/26)

## v0.3.0 2016-2-11

* support `:case_insensitive` option

## v0.2.3 2015-11-5

* improve performance of LCS algorithm [#12](https://github.com/liufengyun/hashdiff/issues/12)

## v0.2.2 2014-10-6

* make library 1.8.7 compatible

## v0.2.1 2014-7-13

* yield added/deleted keys for custom comparison

## v0.2.0 2014-3-29

* support custom comparison blocks
* support `:strip`, `:numeric_tolerance` and `:strict` options

## v0.1.0 2013-8-25

* use options for parameters `:delimiter` and `:similarity` in interfaces

## v0.0.6 2013-3-2

* Add parameter for custom property-path delimiter.

## v0.0.5 2012-7-1

* fix a bug in judging whehter two objects are similiar.
* add more spec test for `.best_diff`

## v0.0.4 2012-6-24

Main changes in this version is to output the whole object in addition & deletion, instead of recursely add/deletes the object.

For example, `diff({a:2, c:[4, 5]}, {a:2}) will generate following output:

    [['-', 'c', [4, 5]]]

instead of following:

    [['-', 'c[0]', 4], ['-', 'c[1]', 5], ['-', 'c', []]]
