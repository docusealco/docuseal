cldr-plurals-runtime-rb
=================

[![Build Status](https://travis-ci.org/camertron/cldr-plurals-runtime-rb.svg?branch=master)](http://travis-ci.org/camertron/cldr-plurals-runtime-rb)

Ruby runtime methods for CLDR plural rules (see camertron/cldr-plurals).

## Installation

`gem install cldr-plurals-runtime-rb`

## Usage

```ruby
require 'cldr-plurals/ruby_runtime'
```

## Functionality

The CLDR data set contains [plural information](http://unicode.org/cldr/trac/browser/tags/release-26-d04/common/supplemental/plurals.xml) for numerous languages in an expression-based [format](http://www.unicode.org/reports/tr35/tr35-numbers.html#Language_Plural_Rules) defined by Unicode's TR35. The document describes how to determine the various parts of a number and how to use those parts to determine the plural rule. The parts as they appear in TR35 are:

| Symbol | Value                                                          |
|:-------|----------------------------------------------------------------|
| n      | absolute value of the source number (integer and decimals).    |
| i      | integer digits of n.                                           |
| v      | number of visible fraction digits in n, with trailing zeros.   |
| w      | number of visible fraction digits in n, without trailing zeros.|
| f      | visible fractional digits in n, with trailing zeros.           |
| t      | visible fractional digits in n, without trailing zeros.        |
| c/e    | compact decimal exponent value                                 |

cldr-plurals-runtime-rb is an implementation of these calculations in Ruby. You can use them via the `CldrPlurals::RubyRuntime` module. Note that all methods take a stringified number as input:

```ruby
num = '1.04'
CldrPlurals::RubyRuntime.n(num)  # => 1.04
CldrPlurals::RubyRuntime.i(num)  # => 1
```

This runtime was created primarily for the [cldr-plurals](https://github.com/camertron/cldr-plurals) project, which can parse and emit Ruby code for a set of plural rules. Here's an example:

```ruby
require 'cldr-plurals'
require 'cldr-plurals/ruby_runtime'

rules = CldrPlurals::Compiler::RuleList.new(:ru).tap do |rule_list|
  rule_list.add_rule(:one, 'v = 0 and i % 10 = 1 and i % 100 != 11')
  rule_list.add_rule(:few, 'v = 0 and i % 10 = 2..4 and i % 100 != 12..14')
  rule_list.add_rule(:many, 'v = 0 and i % 10 = 0 or v = 0 and i % 10 = 5..9 or v = 0 and i % 100 = 11..14')
end

ruby_code = rules.to_code(:ruby)
rule_proc = eval(ruby_code)

rule_proc.call('3', CldrPlurals::RubyRuntime)  # => :few
```

## Requirements

No external requirements.

## Running Tests

`bundle exec rake` should do the trick. Alternatively you can run `bundle exec rspec`, which does the same thing.

## Authors

* Cameron C. Dutro: http://github.com/camertron
