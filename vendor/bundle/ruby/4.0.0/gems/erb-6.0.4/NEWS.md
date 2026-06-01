# Changelog

## 6.0.4

* Prohibit `def_method` on marshal-loaded ERB instances

## 6.0.3

* Exclude some files from published gem https://github.com/ruby/erb/pull/108

## 6.0.2

* Freeze `src` in `ERB#initialize` for Ractor compatibility https://github.com/ruby/erb/pull/105

## 6.0.1

* Freeze `ERB::Compiler::TrimScanner::ERB_STAG` for Ractor compatibility

## 6.0.0

* Remove `safe_level` and further positional arguments from `ERB.new`
* Remove deprecated constant `ERB::Revision`

## 5.1.3

* Release v5.1.2 with trusted publishing for JRuby

## 5.1.2

* Add `changelog_uri` to spec metadata https://github.com/ruby/erb/pull/89

## 5.1.1

* Fix integer overflow that is introduced at v5.1.0

## 5.1.0

*  html_escape: Avoid buffer allocation for strings with no escapable character https://github.com/ruby/erb/pull/87

## 5.0.3

* Update help of erb(1) [#85](https://github.com/ruby/erb/pull/85)

## 5.0.2

* Declare escape functions as Ractor-safe [#63](https://github.com/ruby/erb/pull/63)

## 5.0.1

* Rescue `LoadError` when failing to load `erb/escape`

## 5.0.0

* Bump `required_ruby_version` to Ruby 3.2+ [#60](https://github.com/ruby/erb/pull/60)
* Drop `cgi` from runtime dependencies [#59](https://github.com/ruby/erb/pull/59)
* Make `ERB::VERSION` public

## 4.0.4

* Skip building the C extension for JRuby [#52](https://github.com/ruby/erb/pull/52)

## 4.0.3

* Enable `frozen_string_literal` in all files [#49](https://github.com/ruby/erb/pull/49)

## 4.0.2

* Fix line numbers after multi-line `<%#` [#42](https://github.com/ruby/erb/pull/42)

## 4.0.1

* Stop building the C extension for TruffleRuby [#39](https://github.com/ruby/erb/pull/39)

## 4.0.0

* Optimize `ERB::Util.html_escape` [#27](https://github.com/ruby/erb/pull/27)
  * No longer duplicate an argument string when nothing is escaped.
     * This makes `ERB::Util.html_escape` faster than `CGI.escapeHTML` in no-escape cases.
  * It skips calling `#to_s` when an argument is already a String.
* Define `ERB::Escape.html_escape` as an alias to `ERB::Util.html_escape` [#38](https://github.com/ruby/erb/pull/38)
  * `ERB::Util.html_escape` is known to be monkey-patched by Rails.
    `ERB::Escape.html_escape` is useful when you want a non-monkey-patched version.
* Drop deprecated `-S` option from `erb` command

## 3.0.0

* Bump `required_ruby_version` to Ruby 2.7+ [#23](https://github.com/ruby/erb/pull/23)
* `ERB::Util.url_encode` uses a native implementation [#23](https://github.com/ruby/erb/pull/23)
* Fix a bug that a magic comment with a wrong format could be detected [#6](https://github.com/ruby/erb/pull/6)

## 2.2.3

* Bump `required_ruby_version` from 2.3 to 2.5 as it has never been supported [#3](https://github.com/ruby/erb/pull/3)

## 2.2.2

* `ERB.version` returns just a version number
* `ERB::Revision` is deprecated

## 2.2.1

* `ERB#initialize` warns `safe_level` and later arguments even without -w

## 2.2.0

* Ruby 3.0 promoted ERB to a default gem
