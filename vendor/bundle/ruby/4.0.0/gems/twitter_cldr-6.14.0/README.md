## twitter-cldr-rb ![Unit Tests](https://github.com/twitter/twitter-cldr-rb/actions/workflows/unit_tests.yml/badge.svg?branch=master) [![Code Climate](https://codeclimate.com/github/twitter/twitter-cldr-rb.png)](https://codeclimate.com/github/twitter/twitter-cldr-rb) [![Coverage Status](https://coveralls.io/repos/twitter/twitter-cldr-rb/badge.png?branch=master)](https://coveralls.io/r/twitter/twitter-cldr-rb?branch=master)

TwitterCldr uses Unicode's Common Locale Data Repository (CLDR) to format certain types of text into their
localized equivalents.  Currently supported types of text include dates, times, currencies, decimals, percentages, and symbols.

## Installation

`gem install twitter_cldr`

## Usage

```ruby
require 'twitter_cldr'
```

### Basics

Get a list of all currently supported locales (these are all supported on twitter.com):

```ruby
TwitterCldr.supported_locales             # [:af, :ar, :az, :be, :bg, :bn, ... ]
```

Determine if a locale is supported by TwitterCLDR:

```ruby
TwitterCldr.supported_locale?(:es)        # true
TwitterCldr.supported_locale?(:xx)        # false
```


TwitterCldr patches core Ruby objects like `Integer` and `Date` to make localization as straightforward as possible.

### Numbers

`Integer` and `Float` objects are supported (as well as `Fixnum` and `Bignum` for Ruby versions < 2.4).  Here are some examples:

```ruby
# default formatting with to_s
1337.localize(:es).to_s                                    # "1.337"

# currencies, default USD
1337.localize(:es).to_currency.to_s                        # "1.337,00 US$"
1337.localize(:es).to_currency.to_s(:currency => "EUR")    # "1.337,00 €"

# percentages
1337.localize(:es).to_percent.to_s                         # "1.337 %"
1337.localize(:es).to_percent.to_s(:precision => 2)        # "1.337,00 %"

# decimals
1337.localize(:es).to_decimal.to_s(:precision => 3)        # "1.337,000"
```

**Note**: The `:precision` option can be used with all these number formatters.

Behind the scenes, these convenience methods are creating instances of `LocalizedNumber`.  You can do the same thing if you're feeling adventurous:

```ruby
num = TwitterCldr::Localized::LocalizedNumber.new(1337, :es)
num.to_currency.to_s  # ...etc
```



#### More on Currencies

If you're looking for a list of supported currencies, use the `TwitterCldr::Shared::Currencies` class:

```ruby
# all supported currency codes
TwitterCldr::Shared::Currencies.currency_codes             # ["ADP", "AED", "AFA", "AFN", ... ]

# data for a specific currency code
TwitterCldr::Shared::Currencies.for_code("CAD")            # {:currency=>:CAD, :name=>"Canadian Dollar", :cldr_symbol=>"CA$", :symbol=>"CA$", :code_points=>[67, 65, 36]}
```

#### Short / Long Decimals

In addition to formatting regular decimals, TwitterCLDR supports short and long decimals.  Short decimals abbreviate the notation for the appropriate power of ten, for example "1M" for 1,000,000 or "2K" for 2,000.  Long decimals include the full notation, for example "1 million" or "2 thousand".  Long and short decimals can be generated using the appropriate `format` option:

```ruby
2337.localize.to_decimal.to_s(format: :short)     # "2K"
1337123.localize.to_decimal.to_s(format: :short)  # "1M"

2337.localize.to_decimal.to_s(format: :long)      # "2 thousand"
1337123.localize.to_decimal.to_s(format: :long)   # "1 million"
```

### Units

TwitterCLDR supports formatting numbers with an attached unit, for example "12 degrees Celsius". It's easy to make use of this functionality via the `#to_unit` method:

```ruby
12.localize.to_unit.length_mile  # "12 miles"
12.localize(:ru).to_unit.length_mile  # "12 милях"
```
Units support a few different forms, long, short, and narrow:

```ruby
12.localize.to_unit.mass_kilogram(form: :short)  # "12 kg"
```

To get a list of all available unit types, use the `#unit_types` method:

```ruby
unit = 12.localize.to_unit
unit.unit_types  # => [:length_mile, :temperature_celsius, :mass_kilogram, ...]
```





### Number Spellout, Ordinalization, and More

TwitterCLDR's rule-based number formatters are capable of transforming integers into their written equivalents. Note that rule-based formatting of decimal numbers is currently not supported for languages other than English.

#### Spellout

For easy spellout formatting, check out the `LocalizedNumber#spellout` method:

```ruby
123.localize.spellout     # one hundred twenty-three
25_641.localize.spellout  # twenty-five thousand six hundred forty-one
```

As always, you can call `#localize` with a locale symbol:

```ruby
123.localize(:es).spellout     # ciento veintitrés
25_641.localize(:ru).spellout  # двадцать пять тысяч шестьсот сорок один
```

#### Ordinalization and More

The available rule-based number formats defined by the CLDR data set vary by language. Some languages support ordinal and cardinal numbers, occasionally with an additional masculine/feminine option, while others do not. You'll need to consult the list of available formats for your language.

Rule-based number formats are categorized by groups, and within groups by rulesets. You'll need to specify both to make use of all the available formats for your language.

To get a list of supported groups, use the `#group_names` method:

```ruby
123.localize(:pt).rbnf.group_names  # ["SpelloutRules", "OrdinalRules"]
```

To get a list of supported rulesets for a group name, use the `#rule_set_names_for_group` method:

```ruby
# ["digits-ordinal-masculine", "digits-ordinal-feminine", "digits-ordinal"]
123.localize(:pt).rbnf.rule_set_names_for_group("OrdinalRules")
```

Once you've chosen a group and ruleset, you can pass them to the `to_rbnf_s` method:

```ruby
123.localize(:pt).to_rbnf_s("OrdinalRules", "digits-ordinal-feminine")  # 123a
123.localize(:pt).to_rbnf_s("OrdinalRules", "digits-ordinal-masculine") # 123o
```

For comparison, here's what English ordinal formatting looks like:

```ruby
123.localize.to_rbnf_s("OrdinalRules", "digits-ordinal")  # 123rd
```

For English (and other languages), you can also specify an ordinal spellout:

```ruby
123.localize.to_rbnf_s("SpelloutRules", "spellout-ordinal")  # one hundred twenty-third
123.localize(:pt).to_rbnf_s("SpelloutRules", "spellout-ordinal-masculine")  # centésimo vigésimo terceiro
```

### Dates and Times

`Time`, and `DateTime` objects are supported.  `Date` objects are supported transiently:

```ruby
DateTime.now.localize(:es).to_full_s               # "viernes, 14 de febrero de 2014, 12:20:05 (tiempo universal coordinado)"
DateTime.now.localize(:es).to_long_s               # "14 de febrero de 2014, 12:20:05 UTC"
DateTime.now.localize(:es).to_medium_s             # "14 feb 2014, 12:20:05"
DateTime.now.localize(:es).to_short_s              # "14/2/14, 12:20"

Time.now.localize(:es).to_full_s                   # "12:20:05 (tiempo universal coordinado)"
Time.now.localize(:es).to_long_s                   # "12:20:05 UTC"
Time.now.localize(:es).to_medium_s                 # "12:20:05"
Time.now.localize(:es).to_short_s                  # "12:20"

DateTime.now.localize(:es).to_date.to_full_s       # "viernes, 14 de febrero de 2014"
DateTime.now.localize(:es).to_date.to_long_s       # "14 de febrero de 2014"
DateTime.now.localize(:es).to_date.to_medium_s     # "14 feb 2014"
DateTime.now.localize(:es).to_date.to_short_s      # "14/2/14"
```

The default CLDR data set only includes 4 date formats, full, long, medium, and short.  See below for a list of additional formats.

Behind the scenes, these convenience methods are creating instances of `LocalizedDate`, `LocalizedTime`, and `LocalizedDateTime`.  You can do the same thing if you're feeling adventurous:



```ruby
dt = TwitterCldr::Localized::LocalizedDateTime.new(DateTime.now, :es)
dt.to_short_s  # ...etc
```

#### Additional Date Formats

Besides the default date formats, CLDR supports a number of additional ones.  The list of available formats varies for each locale.  To get a full list, use the `additional_formats` method:

```ruby
# ["Bh", "Bhm", "Bhms", "E", "EBhm", "EBhms", "EEEEd", "EHm", "EHms", "Ed", "Ehm", "Ehms", ... ]
DateTime.now.localize(:ja).additional_formats
```

You can use any of the returned formats as the argument to the `to_additional_s` method:

```ruby
# "14日金曜日"
DateTime.now.localize(:ja).to_additional_s("EEEEd")
```

It's important to know that, even though any given format may not be available across locales, TwitterCLDR will do it's best to approximate if no exact match can be found.

##### List of additional date format examples for English:

| Format     | Output                 |
|:-----------|------------------------|
| Bh         | 12 in the afternoon    |
| Bhm        | 12:20 in the afternoon |
| Bhms       | 12:20:05 in the afternoon |
| E          | Fri                    |
| EBhm       | Fri 12:20 in the afternoon |
| EBhms      | Fri 12:20:05 in the afternoon |
| EHm        | Fri 12:20              |
| EHms       | Fri 12:20:05           |
| Ed         | 14 Fri                 |
| Ehm        | Fri 12:20 PM           |
| Ehms       | Fri 12:20:05 PM        |
| Gy         | 2014 CE                |
| GyMMM      | Feb 2014 CE            |
| GyMMMEd    | Fri, Feb 14, 2014 CE   |
| GyMMMd     | Feb 14, 2014 CE        |
| GyMd       | 2/14/2014 CE           |
| H          | 12                     |
| Hm         | 12:20                  |
| Hms        | 12:20:05               |
| Hmsv       | 12:20:05 GMT           |
| Hmv        | 12:20 GMT              |
| M          | 2                      |
| MEd        | Fri, 2/14              |
| MMM        | Feb                    |
| MMMEd      | Fri, Feb 14            |
| MMMMW      | week 3 of February     |
| MMMMd      | February 14            |
| MMMd       | Feb 14                 |
| Md         | 2/14                   |
| d          | 14                     |
| h          | 12 PM                  |
| hm         | 12:20 PM               |
| hms        | 12:20:05 PM            |
| hmsv       | 12:20:05 PM GMT        |
| hmv        | 12:20 PM GMT           |
| ms         | 20:05                  |
| y          | 2014                   |
| yM         | 2/2014                 |
| yMEd       | Fri, 2/14/2014         |
| yMMM       | Feb 2014               |
| yMMMEd     | Fri, Feb 14, 2014      |
| yMMMM      | February 2014          |
| yMMMd      | Feb 14, 2014           |
| yMd        | 2/14/2014              |
| yQQQ       | Q1 2014                |
| yQQQQ      | 1st quarter 2014       |
| yw         | week 7 of 2014         |



#### Relative Dates and Times

In addition to formatting full dates and times, TwitterCLDR supports relative time spans via several convenience methods and the `LocalizedTimespan` class.  TwitterCLDR tries to guess the best time unit (eg. days, hours, minutes, etc) based on the length of the time span.  Unless otherwise specified, TwitterCLDR will use the current date and time as the reference point for the calculation.

```ruby
(DateTime.now - 1).localize.ago.to_s        # "1 day ago"
(DateTime.now - 0.5).localize.ago.to_s      # "12 hours ago"  (i.e. half a day)

(DateTime.now + 1).localize.until.to_s      # "in 1 day"
(DateTime.now + 0.5).localize.until.to_s    # "in 12 hours"
```

Specify other locales:

```ruby
(DateTime.now - 1).localize(:de).ago.to_s        # "vor 1 Tag"
(DateTime.now + 1).localize(:de).until.to_s      # "in 1 Tag"
```

Force TwitterCLDR to use a specific time unit by including the `:unit` option:

```ruby
(DateTime.now - 1).localize(:de).ago.to_s(:unit => :hour)        # "vor 24 Stunden"
(DateTime.now + 1).localize(:de).until.to_s(:unit => :hour)      # "in 24 Stunden"
```

Specify a different reference point for the time span calculation:

```ruby
# 86400 = 1 day in seconds, 259200 = 3 days in seconds
(Time.now + 86400).localize(:de).ago(:base_time => (Time.now + 259200)).to_s(:unit => :hour)  # "vor 48 Stunden"
```

Behind the scenes, these convenience methods are creating instances of `LocalizedTimespan`, whose constructor accepts a number of seconds as the first argument.  You can do the same thing if you're feeling adventurous:

```ruby

ts = TwitterCldr::Localized::LocalizedTimespan.new(86400, :locale => :de)
ts.to_s                         # "in 1 Tag"
ts.to_s(:unit => :hour)         # "in 24 Stunden"


ts = TwitterCldr::Localized::LocalizedTimespan.new(-86400, :locale => :de)
ts.to_s                         # "vor 1 Tag"
ts.to_s(:unit => :hour)         # "vor 24 Stunden"
```

By default, timespans are exact representations of a given unit of elapsed time.  TwitterCLDR also supports approximate timespans which round up to the nearest larger unit.  For example, "44 seconds" remains "44 seconds" while "45 seconds" becomes "1 minute".  To approximate, pass the `:approximate => true` option into `to_s`:

```ruby
TwitterCldr::Localized::LocalizedTimespan.new(44).to_s(:approximate => true)  # "in 44 seconds"
TwitterCldr::Localized::LocalizedTimespan.new(45).to_s(:approximate => true)  # "in 1 minute"
TwitterCldr::Localized::LocalizedTimespan.new(52).to_s(:approximate => true)  # "in 1 minute"
```

### Timezones

Timezones can be specified for any instance of `LocalizedTime`, `LocalizedDate`, or `LocalizedDateTime` via the `with_timezone` function:

```ruby
# "lunes, 4 de noviembre de 2019, 16:00:00 (hora estándar del Pacífico)"
DateTime.new(2019, 11, 5).localize(:es).with_timezone('America/Los_Angeles').to_full_s
```

Any IANA timezone can be used provided it is available via the [tzinfo](https://github.com/tzinfo/tzinfo) gem. TZInfo references any timezone data available on your system, but will use the data encapsulated in the [tzinfo-data](https://github.com/tzinfo/tzinfo-data) gem if it is bundled with your application. If you're seeing discrepancies between, for example, production and development environments, consider bundling tzinfo-data.

#### Timezone Formats

In addition to including timezones in formatted dates and times, TwitterCLDR provides access to timezone formats via the `TwitterCldr::Timezones::Timezone` object.

Timezone objects are specified via a combination of timezone ID and locale:

```ruby

tz = TwitterCldr::Timezones::Timezone.instance('Australia/Brisbane', :en)
```

A list of available timezone formats can be retrieved like so:

```ruby
TwitterCldr::Timezones::Timezone::ALL_FORMATS
```

Format a timezone by calling the `#display_name_for` method:

```ruby
# "Brisbane Time"
tz.display_name_for(DateTime.new(2019, 11, 5), :generic_location)

# "Australian Eastern Standard Time"
tz.display_name_for(DateTime.new(2019, 11, 5), :generic_long)
```

`#display_name_for` also accepts arguments for resolving ambiguous times. See [TZInfo Documentation](https://www.rubydoc.info/gems/tzinfo/TZInfo/Timezone#period_for_local-instance_method) for more information.

### Calendar Data

CLDR contains a trove of calendar data, much of which can be accessed. One example is names of months, days, years.

```ruby
TwitterCldr::Shared::Calendar.new(:sv).months.take(3) # ["januari", "februari", "mars"]
```


### Lists

TwitterCLDR supports formatting lists of strings as you might do in English by using commas, eg: "Apples, cherries, and oranges".  Use the `localize` method on an array followed by a call to `to_sentence`:

```ruby
["apples", "cherries", "oranges"].localize.to_sentence       # "apples, cherries, and oranges"
["apples", "cherries", "oranges"].localize(:es).to_sentence  # "apples, cherries y oranges"
```

Behind the scenes, these convenience methods are creating instances of `ListFormatter`.  You can do the same thing if you're feeling adventurous:

```ruby
f = TwitterCldr::Formatters::ListFormatter.new(:en)
f.format(["Larry", "Curly", "Moe"])  # "Larry, Curly, and Moe"

f = TwitterCldr::Formatters::ListFormatter.new(:es)
f.format(["Larry", "Curly", "Moe"])  # "Larry, Curly y Moe"
```

The TwitterCLDR `ListFormatter` class is smart enough to handle right-to-left (RTL) text and will format the list "backwards" in these cases (note that what looks backwards to English speakers looks frontwards for RTL speakers).  See the section on handling bidirectional text below for more information.

### Plural Rules

Some languages, like English, have "countable" nouns.  You probably know this concept better as "plural" and "singular", i.e. the difference between "strawberry" and "strawberries".  Other languages, like Russian, have three plural forms: one (numbers ending in 1), few (numbers ending in 2, 3, or 4), and many (everything else).  Still other languages like Japanese don't use countable nouns at all.

TwitterCLDR makes it easy to find the plural rules for any numeric value:

```ruby
1.localize(:ru).plural_rule                                # :one
2.localize(:ru).plural_rule                                # :few
5.localize(:ru).plural_rule                                # :many
10.0.localize(:ru).plural_rule                             # :other
```

Behind the scenes, these convenience methods use the `TwitterCldr::Formatters::Plurals::Rules` class.  You can do the same thing (and a bit more) if you're feeling adventurous:

```ruby
# get all rules for the default locale
TwitterCldr::Formatters::Plurals::Rules.all                # [:one, :other]

# get all rules for a specific locale
TwitterCldr::Formatters::Plurals::Rules.all_for(:es)       # [:one, :many, :other]
TwitterCldr::Formatters::Plurals::Rules.all_for(:ru)       # [:one, :few, :many, :other]

# get the rule for a number in a specific locale
TwitterCldr::Formatters::Plurals::Rules.rule_for(1, :ru)   # :one
TwitterCldr::Formatters::Plurals::Rules.rule_for(2, :ru)   # :few
```

### Plurals

In addition to providing access to plural rules, TwitterCLDR allows you to embed plurals directly in your source code:

```ruby
replacements = {
  :horse_count => 3,
  :horses => {
    :one => "is 1 horse",
    :other => "are %{horse_count} horses"
  }
}

# "there are 3 horses in the barn"
"there %{horse_count:horses} in the barn".localize % replacements
```

Because providing a pluralization hash with the correct plural rules can be difficult, you can also embed plurals as a JSON hash into your string:

```ruby
str = 'there %<{ "horse_count": { "one": "is one horse", "other": "are %{horse_count} horses" } }> in the barn'

# "there are 3 horses in the barn"
str.localize % { :horse_count => 3 }
```

NOTE: If you're using TwitterCLDR with Rails 3, you may see an error if you try to use the `%` function on a localized string in your views.  Strings in views in Rails 3 are instances of `SafeBuffer`, which patches the `gsub` method that the TwitterCLDR plural formatter relies on.  To fix this issue, simply call `to_str` on any `SafeBuffer` before calling `localize`.  More info [here](https://github.com/rails/rails/issues/1555).  An example:

```ruby
# throws an error in Rails 3 views:
'%<{"count": {"one": "only one", "other": "tons more!"}}'.localize % { :count => 2 }

# works just fine:
'%<{"count": {"one": "only one", "other": "tons more!"}}'.to_str.localize % { :count => 2 }
```

The `LocalizedString` class supports all forms of interpolation:

```ruby
# Ruby
"five euros plus %.3f in tax" % (13.25 * 0.087)
"there are %{count} horses in the barn" % { :count => "5" }

# with TwitterCLDR
"five euros plus %.3f in tax".localize % (13.25 * 0.087)
"there are %{count} horses in the barn".localize % { :count => "5" }
```

When you pass a Hash as an argument and specify placeholders with `%<foo>d`, TwitterCLDR will interpret the hash values as named arguments and format the string according to the instructions appended to the closing `>`:

```ruby
"five euros plus %<percent>.3f in %{noun}".localize % { :percent => 13.25 * 0.087, :noun => "tax" }
```

### World Languages

You can use the localize convenience method on language code symbols to get their equivalents in another language:

```ruby
:es.localize(:es).as_language_code                         # "español"
:ru.localize(:es).as_language_code                         # "ruso"
```

Behind the scenes, these convenience methods are creating instances of `LocalizedSymbol`.  You can do the same thing if you're feeling adventurous:

```ruby
ls = TwitterCldr::Localized::LocalizedSymbol.new(:ru, :es)
ls.as_language_code  # "ruso"
```

In addition to translating language codes, TwitterCLDR provides access to the full set of supported languages via the `TwitterCldr::Shared::Languages` class:

```ruby
# get all languages for the default locale
TwitterCldr::Shared::Languages.all                                                  # { ... :vi => "Vietnamese", :"zh-Hant" => "Traditional Chinese" ... }

# get all languages for a specific locale
TwitterCldr::Shared::Languages.all_for(:es)                                         # { ... :vi => "vietnamita", :"zh-Hant" => "chino tradicional" ... }

# get a language by its code for the default locale
TwitterCldr::Shared::Languages.from_code(:'zh-Hant')                                # "Traditional Chinese"

# get a language from its code for a specific locale
TwitterCldr::Shared::Languages.from_code_for_locale(:'zh-Hant', :es)                # "chino tradicional"

# translate a language from one locale to another
# signature: translate_language(lang, source_locale, destination_locale)
TwitterCldr::Shared::Languages.translate_language("chino tradicional", :es, :en)    # "Traditional Chinese"
TwitterCldr::Shared::Languages.translate_language("Traditional Chinese", :en, :es)  # "chino tradicional"
```

### World Territories

You can use the localize convenience method on territory code symbols to get their equivalents in another language:

```ruby
:gb.localize(:pt).as_territory                         # "Reino Unido"
:cz.localize(:pt).as_territory                         # "Tchéquia"
```

Behind the scenes, these convenience methods are creating instances of `LocalizedSymbol`.  You can do the same thing if you're feeling adventurous:

```ruby
ls = TwitterCldr::Localized::LocalizedSymbol.new(:gb, :pt)
ls.as_territory  # "Reino Unido"
```

In addition to translating territory codes, TwitterCLDR provides access to the full set of supported methods via the `TwitterCldr::Shared::Territories` class:

```ruby
# get all territories for the default locale
TwitterCldr::Shared::Territories.all                                                 # { ... :tl => "Timor-Leste", :tm => "Turkmenistan" ... }

# get all territories for a specific locale
TwitterCldr::Shared::Territories.all_for(:pt)                                        # { ... :tl => "Timor-Leste", :tm => "Turcomenistão" ... }

# get a territory by its code for the default locale
TwitterCldr::Shared::Territories.from_territory_code(:'gb')                          # "United Kingdom"

# get a territory from its code for a specific locale
TwitterCldr::Shared::Territories.from_territory_code_for_locale(:gb, :pt)            # "Reino Unido"

# translate a territory from one locale to another
# signature: translate_territory(territory_name, source_locale, destination_locale)
TwitterCldr::Shared::Territories.translate_territory("Reino Unido", :pt, :en)        # "United Kingdom"
TwitterCldr::Shared::Territories.translate_territory("U.K.", :en, :pt)               # "Reino Unido"
```

### Postal Codes

The CLDR contains postal code validation regexes for a number of countries.

```ruby
# United States
postal_code = TwitterCldr::Shared::PostalCodes.for_territory(:us) 
postal_code.valid?("94103")     # true
postal_code.valid?("9410")      # false

# England (Great Britain)
postal_code = TwitterCldr::Shared::PostalCodes.for_territory(:gb) 
postal_code.valid?("BS98 1TL")  # true

# Sweden
postal_code = TwitterCldr::Shared::PostalCodes.for_territory(:se) 
postal_code.valid?("280 12")    # true

# Canada
postal_code = TwitterCldr::Shared::PostalCodes.for_territory(:ca) 
postal_code.valid?("V3H 1Z7")   # true
```

Match all valid postal codes in a string with the `#find_all` method:

```ruby
# United States
postal_code = TwitterCldr::Shared::PostalCodes.for_territory(:us) 
postal_code.find_all("12345 23456")    # ["12345", "23456"]
```

Get a list of supported territories by using the `#territories` method:

```ruby
TwitterCldr::Shared::PostalCodes.territories  # [:ac, :ad, :af, :ai, :al, ... ]
```

Just want the regex?  No problem:

```ruby
postal_code = TwitterCldr::Shared::PostalCodes.for_territory(:us) 
postal_code.regexp  # /(\d{5})(?:[ \-](\d{4}))?/
```

Get a sample of valid postal codes with the `#sample` method:

```ruby
postal_code.sample(5)  # ["33623-6826", "59924", "59999", "42268-1200", "68209-4464"]
```

### Phone Codes

Telephone codes were deprecated and have now been removed from the CLDR data set. They have been removed from TwitterCLDR as of v5.0.0.

### Language Codes

Over the years, different standards for language codes have accumulated.  Probably the two most popular are ISO-639 and BCP-47 and their children.  TwitterCLDR provides a way to convert between these codes programmatically.

```ruby
TwitterCldr::Shared::LanguageCodes.convert(:es, :from => :bcp_47, :to => :iso_639_2)  # :spa
```

Use the `standards_for` method to get the standards that are available for conversion from a given code.  In the example below, note that the first argument, `:es`, is the correct BCP-47 language code for Spanish, which is the second argument.  The return value comprises all the available conversions:

```ruby
# [:bcp_47, :iso_639_1, :iso_639_2, :iso_639_3]
TwitterCldr::Shared::LanguageCodes.standards_for(:es, :bcp_47)
```

Get a list of supported standards for a full English language name:

```ruby
# [:bcp_47, :iso_639_1, :iso_639_2, :iso_639_3]
TwitterCldr::Shared::LanguageCodes.standards_for_language(:Spanish)
```

Get a list of supported languages:

```ruby
TwitterCldr::Shared::LanguageCodes.languages  # [:Arabic, :German, :Norwegian, :Spanish, ... ]
```

Determine valid standards:

```ruby
TwitterCldr::Shared::LanguageCodes.valid_standard?(:iso_639_1)  # true
TwitterCldr::Shared::LanguageCodes.valid_standard?(:blarg)      # false
```

Determine valid codes:

```ruby
TwitterCldr::Shared::LanguageCodes.valid_code?(:es, :bcp_47)     # true
TwitterCldr::Shared::LanguageCodes.valid_code?(:es, :iso_639_2)  # false
```

Convert the full English name of a language into a language code:

```ruby
TwitterCldr::Shared::LanguageCodes.from_language(:Spanish, :iso_639_2)  # :spa
```

Convert a language code into it's full English name:

```ruby
TwitterCldr::Shared::LanguageCodes.to_language(:spa, :iso_639_2)  # "Spanish"
```

**NOTE**: All of the functions in `TwitterCldr::Shared::LanguageCodes` accept both symbol and string parameters.

### Territories Containment

Provides an API for determining territories containment as described [here](http://www.unicode.org/cldr/charts/25/supplemental/territory_containment_un_m_49.html):

```ruby
TwitterCldr::Shared::TerritoriesContainment.children('151') # ["BG", "BY", "CZ", "HU", "MD", "PL", "RO", "RU", "SK", "SU", "UA", ... ]
TwitterCldr::Shared::TerritoriesContainment.children('RU')  # []

TwitterCldr::Shared::TerritoriesContainment.parents('013') # ["003", "019", "419"]
TwitterCldr::Shared::TerritoriesContainment.parents('001') # []

TwitterCldr::Shared::TerritoriesContainment.contains?('151', 'RU') # true
TwitterCldr::Shared::TerritoriesContainment.contains?('419', 'BZ') # true
TwitterCldr::Shared::TerritoriesContainment.contains?('419', 'FR') # false
```

You can also use `Territory` class and `to_territory` method in `LocalizedString` class to access these features:

```ruby
TwitterCldr::Shared::Territory.new("013").parents # ["003", "019", "419"]
'419'.localize.to_territory.contains?('BZ') # true
```

### Unicode Regular Expressions

Unicode regular expressions are an extension of the normal regular expression syntax. All of the changes are local to the regex's character class feature and provide support for multi-character strings, Unicode character escapes, set operations (unions, intersections, and differences), and character sets.

#### Changes to Character Classes

Here's a complete list of the operations you can do inside a Unicode regex's character class.

| Regex              | Description                                                                                                         |
|:-------------------|:--------------------------------------------------------------------------------------------------------------------|
|`[a]`               | The set containing 'a'.                                                                                             |
|`[a-z]`             | The set containing 'a' through 'z' and all letters in between, in Unicode order.                                    |
|`[^a-z]`            | The set containing all characters except 'a' through 'z', that is, U+0000 through 'a'-1 and 'z'+1 through U+10FFFF. |
|`[[pat1][pat2]]`    | The union of sets specified by pat1 and pat2.                                                                       |
|`[[pat1]&[pat2]]`   | The intersection of sets specified by pat1 and pat2.                                                                |
|`[[pat1]-[pat2]]`   | The [symmetric difference](http://en.wikipedia.org/wiki/Symmetric_difference) of sets specified by pat1 and pat2.   |
|`[:Lu:] or \p{Lu}`  | The set of characters having the specified Unicode property; in this case, Unicode uppercase letters.               |
|`[:^Lu:] or \P{Lu}` | The set of characters not having the given Unicode property.                                                        |

For a description of available Unicode properties, see [Wikipedia](http://en.wikipedia.org/wiki/Unicode_character_property#General_Category) (click on "[show]").

#### Using Unicode Regexes

Create Unicode regular expressions via the `#compile` method:

```ruby

regex = TwitterCldr::Shared::UnicodeRegex.compile("[:Lu:]+")
```

Once compiled, instances of `UnicodeRegex` behave just like normal Ruby regexes and support the `#match` and `#=~` methods:

```ruby

regex.match("ABC")  # <MatchData "ABC">
regex =~ "fooABC"   # 3
```

Protip: Try to avoid negation in character classes (eg. [^abc] and \P{Lu}) as it tends to negatively affect both performance when constructing regexes as well as matching.

### Text Segmentation

TwitterCLDR currently supports text segmentation by sentence as described in the [Unicode Technical Report #29](http://www.unicode.org/reports/tr29/). The segmentation algorithm makes use of Unicode regular expressions (described above). Segmentation by word, line, and grapheme boundaries could also be supported if someone wants them.

You can break a string into sentences using the `LocalizedString#each_sentence` method:

```ruby
"The. Quick. Brown. Fox.".localize.each_sentence do |sentence|
  puts sentence.to_s  # "The. ", "Quick. ", "Brown. ", "Fox."
end
```

Under the hood, text segmentation is performed by the `BreakIterator` class (name borrowed from ICU). You can use it directly if you're feeling adventurous:

```ruby

iterator = TwitterCldr::Segmentation::BreakIterator.new(:en)
iterator.each_sentence("The. Quick. Brown. Fox.") do |sentence|
  puts sentence  # "The. ", "Quick. ", "Brown. ", "Fox."
end
```

To improve segmentation accuracy, a list of special segmentation exceptions have been created by the ULI (Unicode Interoperability Technical Committee, yikes what a mouthful). They help with special cases like the abbreviations "Mr." and "Ms." where breaks should not occur. ULI rules are disabled by default, but you can enable them via the `:use_uli_exceptions` option:

```ruby

iterator = TwitterCldr::Segmentation::BreakIterator.new(:en, :use_uli_exceptions => true)
iterator.each_sentence("I like Ms. Murphy, she's nice.") do |sentence|
  puts sentence  # "I like Ms. Murphy, she's nice."
end
```

### Unicode Data

TwitterCLDR provides ways to retrieve individual code points as well as normalize and decompose Unicode text.

Retrieve data for code points:

```ruby

code_point = TwitterCldr::Shared::CodePoint.get(0x1F3E9)
code_point.name             # "LOVE HOTEL"
code_point.bidi_mirrored    # "N"
code_point.category         # "So"
code_point.combining_class  # "0"
```

Convert characters to code points:

```ruby
TwitterCldr::Utils::CodePoints.from_string("¿")  # [191]
```

Convert code points to characters:

```ruby
TwitterCldr::Utils::CodePoints.to_string([0xBF])  # "¿"
```

#### Unicode Properties

Each character in the Unicode standard comes with a set of properties. Property data includes what type of script the character is written in, which version of the standard it was first introduced in, whether it represent a digit or an alphabetical symbol, its casing, and much more. Certain properties are boolean true/false values while others contain a set of property values. For example, the Hiragana letter "く" ("ku") has an `"Alphabetic"` property (i.e. Alphabetic = true) but does not have an `"Uppercase"` property (i.e. Uppercase = false). In addition, "く" has a property of `"Script"` with a property value for `"Script"` of `["Hiragana"]` (Note that property values are always arrays, since a single property can contain more than one property value).

TwitterCLDR supports all the various Unicode properties and can look them up by character or retrieve a set of matching characters for the given property and property value. Let's use "く" again as an example. "く"'s Unicode code point is 12367 (i.e. `'く'.unpack("U*").first`):



```ruby
properties = TwitterCldr::Shared::CodePoint.get(12367).properties

properties.alphabetic   # true
properties.uppercase    # false
properties.script.to_a  # ["Hiragana"]
```

Use `TwitterCldr::Shared::CodePoint.properties` to look up additional property information:






```ruby
properties = TwitterCldr::Shared::CodePoint.properties.code_points_for_property('Script', 'Hiragana')

properties.to_a  # [12353..12438, 12445..12447 ... ]
```

Behind the scenes, these methods are using instances of `TwitterCldr::Shared::PropertiesDatabase`. Most of the time you probably won't need to use your own instance, but it is worth mentioning that `PropertiesDatabase` supplies methods for retrieving a list of available property names and normalizing property names and values. Finally, `TwitterCldr::Shared::CodePoint.properties` is an instance of `PropertiesDatabase` that you can use in place of creating a separate instance.

#### Normalization

Normalize/decompose a Unicode string (NFD, NFKD, NFC, and NFKC implementations available).  Note that the normalized string will almost always look the same as the original string because most character display systems automatically combine decomposed characters.

```ruby
TwitterCldr::Normalization.normalize("français")  # "français"
```

Normalization is easier to see in hex:

```ruby
# [101, 115, 112, 97, 241, 111, 108]
TwitterCldr::Utils::CodePoints.from_string("español")

# [101, 115, 112, 97, 110, 771, 111, 108]
TwitterCldr::Utils::CodePoints.from_string(TwitterCldr::Normalization.normalize("español"))
```

Notice in the example above that the letter "ñ" was transformed from `241` to `110 771`, which represent the "n" and the "˜" respectively.

A few convenience methods also exist for `String` that make it easy to normalize and get code points for strings:

```ruby
# [101, 115, 112, 97, 241, 111, 108]
"español".localize.code_points

# [101, 115, 112, 97, 110, 771, 111, 108]
"español".localize.normalize.code_points
```

Specify a specific normalization algorithm via the `:using` option.  NFD, NFKD, NFC, and NFKC algorithms are all supported (default is NFD):

```ruby
# [101, 115, 112, 97, 110, 771, 111, 108]
"español".localize.normalize(:using => :NFKD).code_points
```

#### Casefolding

Casefolding is, generally speaking, the process of converting uppercase characters to lowercase ones so as to make text uniform and therefore easier to search. The canonical example of this is the German double "s". The "ß" character is transformed into "ss" by casefolding.

```ruby
"Hello, World".localize.casefold.to_s  # hello, world
"Weißrussland".localize.casefold.to_s  # weissrussland
```

Turkic languages make use of the regular and dotted uppercase i characters "I" and "İ". Normal casefolding will convert a dotless uppercase "I" to a lowercase, dotted "i", which is correct in English. Turkic languages however expect the lowercase version of a dotless uppercase "I" to be a lowercase, dotless "ı". Pass the `:t` option to the `casefold` method to force Turkic treatment of "i" characters. By default, the `:t` option is set to true for Turkish and Azerbaijani:

```ruby
"Istanbul".localize.casefold(:t => true).to_s  # ıstanbul
"Istanbul".localize(:tr).casefold.to_s         # ıstanbul
```

### Hyphenation

TwitterCLDR uses data from the LibreOffice project to offer an implementation of [Franklin Liang's hyphenation algorithm](http://www.tug.org/docs/liang/). Try the `#hyphenate` method on instances of `LocalizedString`:

```ruby
'foolhardy undulate'.localize.hyphenate('-').to_s  # fool-hardy un-du-late
```

Since the data doesn't come packaged with CLDR, only a certain subset of locales are supported. To get a list of supported locales, use the `supported_locales` method:





```ruby
TwitterCldr::Shared::Hyphenator.supported_locales  # ["af-ZA", "de-CH", "en-US", ...]
```

You can also ask the `Hyphenator` class if a locale is supported:

```ruby
TwitterCldr::Shared::Hyphenator.supported_locale?(:en)  # true
TwitterCldr::Shared::Hyphenator.supported_locale?(:ja)  # false
```

Create a new hyphenator instance via the `.get` method. If the locale is not supported, `.get` will raise an error.

```ruby
hyphenator = TwitterCldr::Shared::Hyphenator.get(:en)
hyphenator.hyphenate('absolutely', '-')  # ab-so-lutely
```

The `.get` method will identify the best rule set to use by "maximizing" the given locale, a process that tries different combinations of the locale's language, region, and script based on CLDR's likely subtag data. In practice this means passing in `:en` works even though the hyphenator specifically supports en-US and en-GB.

The second argument to `#hyphenate` is the delimiter to use, i.e. the hyphen text to insert at syllable boundaries. By default, the delimiter is the Unicode soft hyphen character (\u00AD). Depending on the system that's used to display the hyphenated text (word processor, browser, etc), the soft hyphen may render differently. Soft hyphens are supposed to be rendered only when the word needs to be displayed on multiple lines, and should be invisible otherwise.

### Sorting (Collation)

TwitterCLDR contains an implementation of the [Unicode Collation Algorithm (UCA)](http://unicode.org/reports/tr10/) that provides language-sensitive text sorting capabilities.  Conveniently, all you have to do is use the `sort` method in combination with the familiar `localize` method.  Notice the difference between the default Ruby sort, which simply compares bytes, and the proper language-aware sort from TwitterCLDR in this German example:

```ruby
["Art", "Wasa", "Älg", "Ved"].sort                       # ["Art", "Ved", "Wasa", "Älg"]
["Art", "Wasa", "Älg", "Ved"].localize(:de).sort.to_a    # ["Älg", "Art", "Ved", "Wasa"]
```

Behind the scenes, these convenience methods are creating instances of `LocalizedArray`, then using the `TwitterCldr::Collation::Collator` class to sort the elements:

```ruby

collator = TwitterCldr::Collation::Collator.new(:de)
collator.sort(["Art", "Wasa", "Älg", "Ved"])      # ["Älg", "Art", "Ved", "Wasa"]
collator.sort!(["Art", "Wasa", "Älg", "Ved"])     # ["Älg", "Art", "Ved", "Wasa"]
```

The `TwitterCldr::Collation::Collator` class also provides methods to compare two strings, get sort keys, and calculate collation elements for individual strings:

```ruby

collator = TwitterCldr::Collation::Collator.new(:de)
collator.compare("Art", "Älg")           # 1
collator.compare("Älg", "Art")           # -1
collator.compare("Art", "Art")           # 0

collator.get_collation_elements("Älg")   # [[39, 5, 143], [0, 157, 5], [61, 5, 5], [51, 5, 5]]

collator.get_sort_key("Älg")             # [39, 61, 51, 1, 134, 157, 6, 1, 143, 7]
```

**Note**: The TwitterCLDR collator does not currently pass all the collation tests provided by Unicode, but for some strange reasons.  See the [summary](https://gist.github.com/f4ee3bd280a2257c5641) of these discrepancies if you're curious.

### Transliteration

Transliteration is the process of converting the text in one language or script into another with the goal of preserving the source language's pronunciation as much as possible. It can be useful in making text pronounceable in the target language. For example, most native English speakers would not be able to read or pronounce Japanese characters like these: "くろねこさま". Transliterating these characters into Latin script yields "kuronekosama", which should be pronounceable by most English speakers (in fact, probably speakers of many languages that use Latin characters). Remember, transliteration isn't translation; the actual meaning of the words is not taken into consideration, only the sound patterns.

TwitterCLDR supports transliteration via the `#transliterate_into` method on `LocalizedString`. For example:

```ruby
"くろねこさま".localize.transliterate_into(:en)  # "kuronekosama"
```

This simple method hides quite a bit of complexity. First, TwitterCLDR identifies the scripts present in the source text. It then attempts to find any available transliterators to convert between the source language and the target language. If more than one transliterator is found, all of them will be applied to the source text.

You can provide hints to the transliterator by providing additional locale information. For example, you can provide a source and target script:

```ruby
"くろねこさま".localize(:ja_Hiragana).transliterate_into(:en_Latin)  # "kuronekosama"
```
You may supply only the target script, only the source script, neither, or both. TwitterCLDR will try to find the best set of transliterators to get the job done.

Behind the scenes, `LocalizedString#transliterate_into` creates instances of `TwitterCldr::Transforms::Transformer`. You can do this too if you're feeling adventurous. Here's our Japanese example again that uses `Transformer`:

```ruby

rule_set = TwitterCldr::Transforms::Transformer.get('Hiragana-Latin')
rule_set.transform('くろねこさま')  # "kuronekosama"
```
Notice that the `.get` method was called with 'Hiragana-Latin' instead of 'ja-en' or something similar. This is because `.get` must be passed an exact transform id. To get a list of all supported transform ids, use the `Transformer#each_transform` method:





```ruby
TwitterCldr::Transforms::Transformer.each_transform.to_a  # ['Hiragana-Latin', 'Gujarati-Bengali', ...]
```

You can also search for transform ids using the `TransformId` class, which will attempt to find the closest matching transformer for the given source and target locales. Note that `.find` will return `nil` if no transformer can be found. You can pass instances of `TransformId` instead of a string when calling `Transformer.get`:






```ruby
TwitterCldr::Transforms::TransformId.find('ja', 'en')  # nil

id = TwitterCldr::Transforms::TransformId.find('ja_Hiragana', 'en')
id.source  # Hiragana
id.target  # Latin

rule_set = TwitterCldr::Transforms::Transformer.get(id)
rule_set.transform('くろねこさま')  # "kuronekosama"
```

### Handling Bidirectional Text

When it comes to displaying text written in both right-to-left (RTL) and left-to-right (LTR) languages, most display systems run into problems.  The trouble is that Arabic or Hebrew text and English text (for example) often get scrambled visually and are therefore difficult to read.  It's not usually the basic ASCII characters like A-Z that get scrambled - it's most often punctuation marks and the like that are confusingly mixed up (they are considered "weak" types by Unicode).

To mitigate this problem, Unicode supports special invisible characters that force visual reordering so that mixed RTL and LTR (called "bidirectional") text renders naturally on the screen.  The Unicode Consortium has developed an algorithm (The Unicode Bidirectional Algorithm, or UBA) that intelligently inserts these control characters where appropriate.  You can make use of the UBA implementation in TwitterCLDR by creating a new instance of `TwitterCldr::Shared::Bidi` using the `from_string` static method, and manipulating it like so:

```ruby

bidi = TwitterCldr::Shared::Bidi.from_string("hello نزوة world", :direction => :RTL)
bidi.reorder_visually!
bidi.to_s
```

**Disclaimer**: Google Translate tells me the Arabic in the example above means "fancy", but my confidence is not very high, especially since all the letters are unattached. Apologies to any native speakers :)

### Unicode YAML Support

The Psych gem that is the default YAML engine in Ruby 1.9 doesn't handle Unicode characters perfectly.  To mitigate this problem, TwitterCLDR contains an adaptation of the [ya2yaml](https://github.com/afunai/ya2yaml) gem by Akira Funai.  Our changes specifically add better dumping of Ruby symbols.  If you can get Mr. Funai's attention, please gently remind him to merge @camertron's pull request so we can use his gem and not have to maintain a separate version :)  Fortunately, YAML parsing can still be done with the usual `YAML.load` or `YAML.load_file`.

You can make use of TwitterCLDR's YAML dumper by calling `localize` and then `to_yaml` on an `Array`, `Hash`, or `String`:

```ruby
{ :hello => "world" }.localize.to_yaml 
["hello", "world"].localize.to_yaml 
"hello, world".localize.to_yaml 
```

Behind the scenes, these convenience methods are using the `TwitterCldr::Shared::YAML` class.  You can do the same thing if you're feeling adventurous:

```ruby
TwitterCldr::Shared::YAML.dump({ :hello => "world" }) 
TwitterCldr::Shared::YAML.dump(["hello", "world"]) 
TwitterCldr::Shared::YAML.dump("hello, world") 
```

## Adding New Locales

TwitterCLDR doesn't support every locale available in the CLDR data set. If the library doesn't support the locale you need, feel free to add it and create a pull request. Adding (or updating) locales is easy. You'll need to run several rake tasks, one with MRI and another with JRuby. You'll also need an internet connection, since most of the tasks require downloading versions of CLDR, ICU, and various Unicode data files.

Under MRI and then JRuby, run the `add_locale` rake task, passing the locale in the square brackets:

```
bundle exec rake add_locale[bo]
```

If you're using rbenv or rvm, try using the `add_locale.sh` script, which will install the required Ruby versions and run the rake tasks:

```
./script/add_locale.sh bo
```

## About Twitter-specific Locales

Twitter tries to always use BCP-47 language codes.  Data from the CLDR doesn't always match those codes however, so TwitterCLDR provides a `convert_locale` method to convert between the two.  All functionality throughout the entire gem defers to `convert_locale` before retrieving CLDR data.  `convert_locale` supports Twitter-supported BCP-47 language codes as well as CLDR locale codes, so you don't have to guess which one to use.  Here are a few examples:

```ruby
TwitterCldr.convert_locale(:'zh-cn')          # :zh
TwitterCldr.convert_locale(:zh)               # :zh
TwitterCldr.convert_locale(:'zh-tw')          # :"zh-Hant"
TwitterCldr.convert_locale(:'zh-Hant')        # :"zh-Hant"

TwitterCldr.convert_locale(:msa)              # :ms
TwitterCldr.convert_locale(:ms)               # :ms
```

There are a few functions in TwitterCLDR that don't require a locale code, and instead use the default locale by calling `TwitterCldr.locale`.  The `locale` function defers to `FastGettext.locale` when the FastGettext library is available, and falls back on :en (English) when it's not.  (Twitter uses the FastGettext gem to retrieve translations efficiently in Ruby).

```ruby
TwitterCldr.get_locale    # will return :en

require 'fast_gettext'
FastGettext.locale = "ru"

TwitterCldr.locale    # will return :ru
```

## Compatibility

TwitterCLDR is fully compatible with Ruby 2.3, 2.4, 2.5, 2.6, 2.7, 3.0, 3.1, 3.2.

## Requirements

No external requirements.

## Running Tests

`bundle exec rake` will run our basic test suite suitable for development.  To run the full test suite, use `bundle exec rake spec:full`.  The full test suite takes considerably longer to run because it runs against the complete normalization and collation test files from the Unicode Consortium.  The basic test suite only runs normalization and collation tests against a small subset of the complete test file.

Tests are written in RSpec.

## Test Coverage

You can run the development test coverage suite (using simplecov) with `bundle exec rake spec:cov`, or the full suite with `bundle exec rake spec:cov:full`.

## JavaScript Support

TwitterCLDR currently supports localization of certain textual objects in JavaScript via the twitter-cldr-js gem.  See [http://github.com/twitter/twitter-cldr-js](http://github.com/twitter/twitter-cldr-js) for details.

## Authors

* Cameron C. Dutro: http://github.com/camertron
* Kirill Lashuk: http://github.com/kl-7
* Portions adapted from the ruby-cldr gem by Sven Fuchs: http://github.com/svenfuchs/ruby-cldr

## Links
* ruby-cldr gem: [http://github.com/svenfuchs/ruby-cldr](http://github.com/svenfuchs/ruby-cldr)
* fast_gettext gem: [https://github.com/grosser/fast_gettext](https://github.com/grosser/fast_gettext)
* CLDR homepage: [http://cldr.unicode.org/](http://cldr.unicode.org/)

## License

Copyright 2025 Twitter, Inc.

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
