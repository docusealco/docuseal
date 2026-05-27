# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module DataReaders
    class DateTimeDataReader < CalendarDataReader

      def date_reader
        @date_reader ||= DateDataReader.new(locale, gather_options)
      end

      def time_reader
        @time_reader ||= TimeDataReader.new(locale, gather_options)
      end

      def tokenizer
        @tokenizer ||= TwitterCldr::Tokenizers::DateTimeTokenizer.new(self)
      end

      def formatter
        @formatter ||= TwitterCldr::Formatters::DateTimeFormatter.new(self)
      end

      protected

      def gather_options
        {
          type: type,
          calendar_type: calendar_type
        }
      end

      def path_for(type, calendar_type)
        [:calendars, calendar_type, :formats, :datetime]
      end

    end
  end
end