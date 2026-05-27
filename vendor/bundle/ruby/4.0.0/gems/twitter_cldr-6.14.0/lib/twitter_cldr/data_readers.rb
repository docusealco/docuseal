# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module DataReaders
    autoload :DataReader,         "twitter_cldr/data_readers/data_reader"
    autoload :NumberDataReader,   "twitter_cldr/data_readers/number_data_reader"
    autoload :CalendarDataReader, "twitter_cldr/data_readers/calendar_data_reader"
    autoload :DateTimeDataReader, "twitter_cldr/data_readers/date_time_data_reader"
    autoload :DateDataReader,     "twitter_cldr/data_readers/date_data_reader"
    autoload :TimeDataReader,     "twitter_cldr/data_readers/time_data_reader"
    autoload :TimespanDataReader, "twitter_cldr/data_readers/timespan_data_reader"
    autoload :AdditionalDateFormatSelector, 'twitter_cldr/data_readers/additional_date_format_selector'
  end
end