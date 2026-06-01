# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Localized
    class LocalizedTimespan < LocalizedObject

      DEFAULT_TYPE = :default
      APPROXIMATE_MULTIPLIER = 0.75

      TIME_IN_SECONDS = {
        second: 1,
        minute: 60,
        hour:   3600,
        day:    86400,
        week:   604800,
        month:  2629743.83,
        year:   31556926
      }

      def initialize(seconds, options = {})
        super(seconds, options[:locale] || TwitterCldr.locale, options)
      end

      def to_s(options = {})
        unit = options[:unit] || calculate_unit(base_obj.abs, options)
        direction = options[:direction] || (base_obj < 0 ? :ago : :until)
        type = options[:type] || DEFAULT_TYPE
        number = calculate_time(base_obj, unit)

        data_reader = TwitterCldr::DataReaders::TimespanDataReader.new(locale, number, {
          unit: unit,
          direction: direction,
          type: type
        })

        tokens = data_reader.tokenizer.tokenize(data_reader.pattern)
        data_reader.formatter.format(tokens, number, options)
      end

      protected

      def calculate_unit(seconds, options = {})
        approximate = options[:approximate]
        approximate = false if approximate.nil?
        multiplier = approximate ? APPROXIMATE_MULTIPLIER : 1

        if seconds < (TIME_IN_SECONDS[:minute] * multiplier) then :second
        elsif seconds < (TIME_IN_SECONDS[:hour] * multiplier) then :minute
        elsif seconds < (TIME_IN_SECONDS[:day] * multiplier) then :hour
        elsif seconds < (TIME_IN_SECONDS[:week] * multiplier) then :day
        elsif seconds < (TIME_IN_SECONDS[:month] * multiplier) then :week
        elsif seconds < (TIME_IN_SECONDS[:year] * multiplier) then :month
        else :year end
      end

      # 0 <-> 29 secs                                                   # => seconds
      # 30 secs <-> 44 mins, 29 secs                                    # => minutes
      # 44 mins, 30 secs <-> 23 hrs, 59 mins, 29 secs                   # => hours
      # 23 hrs, 59 mins, 29 secs <-> 29 days, 23 hrs, 59 mins, 29 secs  # => days
      # 29 days, 23 hrs, 59 mins, 29 secs <-> 1 yr minus 1 sec          # => months
      # 1 yr <-> max time or date                                       # => years
      def calculate_time(seconds, unit)
        (seconds.to_f / TIME_IN_SECONDS[unit].to_f).abs.round.to_i
      end

    end
  end
end