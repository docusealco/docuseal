# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared
    autoload :Bidi,                   'twitter_cldr/shared/bidi'
    autoload :Calendar,               'twitter_cldr/shared/calendar'
    autoload :Casefolder,             'twitter_cldr/shared/casefolder'
    autoload :Caser,                  'twitter_cldr/shared/caser'
    autoload :CodePoint,              'twitter_cldr/shared/code_point'
    autoload :Currencies,             'twitter_cldr/shared/currencies'
    autoload :DayPeriods,             'twitter_cldr/shared/day_periods'
    autoload :Hyphenator,             'twitter_cldr/shared/hyphenator'
    autoload :LanguageCodes,          'twitter_cldr/shared/language_codes'
    autoload :Languages,              'twitter_cldr/shared/languages'
    autoload :LikelySubtags,          'twitter_cldr/shared/likely_subtags'
    autoload :Locale,                 'twitter_cldr/shared/locale'
    autoload :NumberingSystem,        'twitter_cldr/shared/numbering_system'
    autoload :Numbers,                'twitter_cldr/shared/numbers'
    autoload :PhoneCodes,             'twitter_cldr/shared/phone_codes'
    autoload :PostalCodeGenerator,    'twitter_cldr/shared/postal_code_generator'
    autoload :PostalCodes,            'twitter_cldr/shared/postal_codes'
    autoload :Properties,             'twitter_cldr/shared/properties'
    autoload :PropertiesDatabase,     'twitter_cldr/shared/properties_database'
    autoload :PropertyNameAliases,    'twitter_cldr/shared/property_name_aliases'
    autoload :PropertyValueAliases,   'twitter_cldr/shared/property_value_aliases'
    autoload :PropertyNormalizer,     'twitter_cldr/shared/property_normalizer'
    autoload :PropertySet,            'twitter_cldr/shared/property_set'
    autoload :Territories,            'twitter_cldr/shared/territories'
    autoload :TerritoriesContainment, 'twitter_cldr/shared/territories_containment'
    autoload :Territory,              'twitter_cldr/shared/territory'
    autoload :UnicodeRegex,           'twitter_cldr/shared/unicode_regex'
    autoload :UnicodeSet,             'twitter_cldr/shared/unicode_set'
    autoload :Unit,                   'twitter_cldr/shared/unit'
  end
end
