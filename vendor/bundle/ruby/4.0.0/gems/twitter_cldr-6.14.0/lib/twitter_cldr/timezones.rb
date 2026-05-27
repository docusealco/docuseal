# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Timezones
    autoload :GenericLocation,         'twitter_cldr/timezones/generic_location'
    autoload :GmtLocation,             'twitter_cldr/timezones/gmt_location'
    autoload :Iso8601Location,         'twitter_cldr/timezones/iso8601_location'
    autoload :Location,                'twitter_cldr/timezones/location'
    autoload :Timezone,                'twitter_cldr/timezones/timezone'
    autoload :ZoneMeta,                'twitter_cldr/timezones/zone_meta'
  end
end
