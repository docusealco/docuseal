# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Localized
    autoload :LocalizedArray,    'twitter_cldr/localized/localized_array'
    autoload :LocalizedHash,     'twitter_cldr/localized/localized_hash'
    autoload :LocalizedDate,     'twitter_cldr/localized/localized_date'
    autoload :LocalizedDateTime, 'twitter_cldr/localized/localized_datetime'
    autoload :LocalizedNumber,   'twitter_cldr/localized/localized_number'
    autoload :LocalizedObject,   'twitter_cldr/localized/localized_object'
    autoload :LocalizedString,   'twitter_cldr/localized/localized_string'
    autoload :LocalizedSymbol,   'twitter_cldr/localized/localized_symbol'
    autoload :LocalizedTime,     'twitter_cldr/localized/localized_time'
    autoload :LocalizedTimespan, 'twitter_cldr/localized/localized_timespan'
  end
end
