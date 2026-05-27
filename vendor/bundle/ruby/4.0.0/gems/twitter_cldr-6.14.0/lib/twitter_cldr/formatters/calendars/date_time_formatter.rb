# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

# This class has been adapted from Sven Fuch's ruby-cldr gem
# See LICENSE for the accompanying license for his contributions

require 'tzinfo'

module TwitterCldr
  module Formatters
    class DateTimeFormatter < Formatter

      WEEKDAY_KEYS = [:sun, :mon, :tue, :wed, :thu, :fri, :sat].freeze

      METHODS = { # ignoring u, l, g, j, A
        'G' => :era,
        'y' => :year,
        'Y' => :year_of_week_of_year,
        'Q' => :quarter,
        'q' => :quarter_stand_alone,
        'M' => :month,
        'L' => :month_stand_alone,
        'w' => :week_of_year,
        'W' => :week_of_month,
        'd' => :day,
        'D' => :day_of_month,
        'F' => :day_of_week_in_month,
        'E' => :weekday,
        'e' => :weekday_local,
        'c' => :weekday_local_stand_alone,
        'a' => :period,
        'B' => :period,
        'h' => :hour,
        'H' => :hour,
        'K' => :hour,
        'k' => :hour,
        'm' => :minute,
        's' => :second,
        'S' => :second_fraction,
        'z' => :timezone,
        'Z' => :timezone,
        'O' => :timezone,
        'v' => :timezone,
        'V' => :timezone,
        'x' => :timezone,
        'X' => :timezone
      }.freeze

      TZ_PATTERNS = {
        'z'     => :specific_short,
        'zz'    => :specific_short,
        'zzz'   => :specific_short,
        'zzzz'  => :specific_long,
        'Z'     => :iso_basic_local_full,
        'ZZ'    => :iso_basic_local_full,
        'ZZZ'   => :iso_basic_local_full,
        'ZZZZ'  => :long_gmt,
        'ZZZZZ' => :iso_extended_local_fixed,
        'OOOO'  => :long_gmt,
        'O'     => :short_gmt,
        'v'     => :generic_short,
        'vvvv'  => :generic_long,
        'V'     => :zone_id_short,
        'VV'    => :zone_id,
        'VVV'   => :exemplar_location,
        'VVVV'  => :generic_location,
        'X'     => :iso_basic_short,
        'XX'    => :iso_basic_fixed,
        'XXX'   => :iso_extended_fixed,
        'XXXX'  => :iso_basic_full,
        'XXXXX' => :iso_extended_full,
        'x'     => :iso_basic_local_short,
        'xx'    => :iso_basic_local_fixed,
        'xxx'   => :iso_extended_local_fixed,
        'xxxx'  => :iso_basic_local_full,
        'xxxxx' => :iso_extended_local_full
      }.freeze

      protected

      def format_pattern(token, index, obj, options)
        send(METHODS[token.value[0].chr], obj, token.value, token.value.size, options)
      end

      def calendar
        data_reader.calendar
      end

      # There is incomplete era data in CLDR for certain locales like Hindi.
      # Fall back if that happens.
      def era(date, pattern, length, options = {})
        choices = case length
          when 0
            ["", ""]
          when 1..3
            calendar.eras(:abbr)
          else
            calendar.eras(:name)
        end

        if result = choices[date.year < 0 ? 0 : 1]
          result
        else
          era(date, pattern[0..-2], length - 1)
        end
      end

      def year(date, pattern, length, options = {})
        year = date.year.to_s
        year = year.length == 1 ? year : year[-2, 2] if length == 2
        year = year.rjust(length, '0') if length > 1
        year
      end

      def year_of_week_of_year(date, pattern, length, options = {})
        week_fields_for(date)[:year_woy].to_s
      end

      def day_of_week_in_month(date, pattern, length, options = {}) # e.g. 2nd Wed in July
        week_fields_for(date)[:day_of_week_in_month].to_s
      end

      def week_of_month(date, pattern, length, options = {})
        week_fields_for(date)[:week_of_month].to_s
      end

      def week_of_year(date, pattern, length, options = {})
        week_fields_for(date)[:week_of_year].to_s
      end

      def quarter(date, pattern, length, options = {})
        quarter = (date.month.to_i - 1) / 3 + 1
        case length
          when 1
            quarter.to_s
          when 2
            quarter.to_s.rjust(length, '0')
          when 3
            calendar.quarters(:abbreviated, :format)[quarter]
          when 4
            calendar.quarters(:wide, :format)[quarter]
        end
      end

      def quarter_stand_alone(date, pattern, length, options = {})
        quarter = (date.month.to_i - 1) / 3 + 1
        case length
          when 1
            quarter.to_s
          when 2
            quarter.to_s.rjust(length, '0')
          when 3
            raise NotImplementedError, 'requires cldr\'s "multiple inheritance"'
            # calendar[:quarters][:'stand-alone'][:abbreviated][key]
          when 4
            raise NotImplementedError, 'requires cldr\'s "multiple inheritance"'
            # calendar[:quarters][:'stand-alone'][:wide][key]
          when 5
            calendar.quarters(:narrow)[quarter]
        end
      end

      def month(date, pattern, length, options = {})
        case length
          when 1
            date.month.to_s
          when 2
            date.month.to_s.rjust(length, '0')
          when 3
            calendar.months(:abbreviated, :format)[date.month - 1]
          when 4
            calendar.months(:wide, :format)[date.month - 1]
          when 5
            raise NotImplementedError, 'requires cldr\'s "multiple inheritance"'
            # calendar[:months][:format][:narrow][date.month]
          else
            # raise unknown date format
        end
      end

      def month_stand_alone(date, pattern, length, options = {})
        case length
          when 1
            date.month.to_s
          when 2
            date.month.to_s.rjust(length, '0')
          when 3
            calendar.months(:abbreviated)[date.month - 1]
          when 4
            calendar.months(:wide)[date.month - 1]
          when 5
            calendar.months(:narrow)[date.month - 1]
          else
            # raise unknown date format
        end
      end

      def day(date, pattern, length, options = {})
        case length
          when 1
            date.day.to_s
          when 2
            date.day.to_s.rjust(length, '0')
        end
      end

      def weekday(date, pattern, length, options = {})
        key = WEEKDAY_KEYS[date.wday]
        case length
          when 1..3
            calendar.weekdays(:abbreviated, :format)[key]
          when 4
            calendar.weekdays(:wide, :format)[key]
          when 5
            calendar.weekdays(:narrow)[key]
        end
      end

      def weekday_local(date, pattern, length, options = {})
        # "Like E except adds a numeric value depending on the local starting day of the week"
        # CLDR does not contain data as to which day is the first day of the week, so we will assume Monday (Ruby default)
        case length
          when 1..2
            date.cwday.to_s
          else
            weekday(date, pattern, length)
        end
      end

      def weekday_local_stand_alone(date, pattern, length, options = {})
        case length
          when 1
            weekday_local(date, pattern, length)
          else
            weekday(date, pattern, length)
        end
      end

      def period(time, pattern, length, options = {})
        if pattern[0] == 'a'
          return calendar.periods(:wide, :format)[time.strftime('%p').downcase.to_sym]
        end

        period_type = TwitterCldr::Shared::DayPeriods
          .instance(data_reader.locale)
          .period_type_for(time)

        if length <= 3
          calendar.periods(:abbreviated, :format)[period_type]
        elsif length == 4 || length > 5
          calendar.periods(:wide, :format)[period_type]
        else
          # length == 5
          calendar.periods(:narrow, :format)[period_type]
        end
      end

      def hour(time, pattern, length, options = {})
        hour = time.hour
        hour = case pattern[0, 1]
          when 'h' # [1-12]
            hour > 12 ? (hour - 12) : (hour == 0 ? 12 : hour)
          when 'H' # [0-23]
            hour
          when 'K' # [0-11]
            hour > 11 ? hour - 12 : hour
          when 'k' # [1-24]
            hour == 0 ? 24 : hour
        end
        length == 1 ? hour.to_s : hour.to_s.rjust(length, '0')
      end

      def minute(time, pattern, length, options = {})
        length == 1 ? time.min.to_s : time.min.to_s.rjust(length, '0')
      end

      def second(time, pattern, length, options = {})
        length == 1 ? time.sec.to_s : time.sec.to_s.rjust(length, '0')
      end

      def second_fraction(time, pattern, length, options = {})
        raise ArgumentError.new('can not use the S format with more than 6 digits') if length > 6
        (time.usec.to_f / 10 ** (6 - length)).round.to_s.rjust(length, '0')
      end

      def timezone(time, pattern, length, options = {})
        tz = TwitterCldr::Timezones::Timezone.instance(
          options[:timezone] || 'UTC', data_reader.locale
        )
        fmt = TZ_PATTERNS[pattern]

        args = [time, fmt, options[:dst]].compact
        tz.display_name_for(*args)
      end

      # ported from icu4j 64.2
      def week_fields_for(date)
        week_data_cache[date] ||= begin
          eyear = date.year
          day_of_week = date.wday + 1
          day_of_year = date.yday

          # this should come from the CLDR's supplemental data set, but we
          # don't have access to it right now
          first_day_of_week = 1  # assume sunday
          minimal_days_in_first_week = 1  # assume US

          # WEEK_OF_YEAR start
          # Compute the week of the year.  For the Gregorian calendar, valid week
          # numbers run from 1 to 52 or 53, depending on the year, the first day
          # of the week, and the minimal days in the first week.  For other
          # calendars, the valid range may be different -- it depends on the year
          # length.  Days at the start of the year may fall into the last week of
          # the previous year; days at the end of the year may fall into the
          # first week of the next year.  ASSUME that the year length is less than
          # 7000 days.
          year_of_week_of_year = eyear
          rel_dow = (day_of_week + 7 - first_day_of_week) % 7 # 0..6
          rel_dow_jan1 = (day_of_week - day_of_year + 7001 - first_day_of_week) % 7 # 0..6
          woy = (day_of_year - 1 + rel_dow_jan1) / 7 # 0..53

          if (7 - rel_dow_jan1) >= minimal_days_in_first_week
            woy += 1
          end

          # Adjust for weeks at the year end that overlap into the previous or
          # next calendar year.
          if woy == 0
            # We are the last week of the previous year.
            # Check to see if we are in the last week; if so, we need
            # to handle the case in which we are the first week of the
            # next year.

            year_length = (Date.new(eyear, 1, 1) - Date.new(eyear - 1, 1, 1)).to_i

            prev_doy = day_of_year + year_length
            woy = week_number(prev_doy, day_of_week)
            year_of_week_of_year -= 1
          else
            last_doy = (Date.new(eyear + 1, 1, 1) - Date.new(eyear, 1, 1)).to_i
            # Fast check: For it to be week 1 of the next year, the DOY
            # must be on or after L-5, where L is yearLength(), then it
            # cannot possibly be week 1 of the next year:
            #          L-5                  L
            # doy: 359 360 361 362 363 364 365 001
            # dow:      1   2   3   4   5   6   7
            if day_of_year >= (last_doy - 5)
              last_rel_dow = (rel_dow + last_doy - day_of_year) % 7

              if (last_rel_dow < 0)
                last_rel_dow += 7
              end

              if ((6 - last_rel_dow) >= minimal_days_in_first_week) && ((day_of_year + 7 - rel_dow) > last_doy)
                woy = 1;
                year_of_week_of_year += 1
              end
            end
          end

          {
            week_of_year: woy,
            year_woy: year_of_week_of_year,
            week_of_month: week_number(date.mday, day_of_week),
            day_of_week_in_month: (date.mday - 1) / 7 + 1
          }
        end
      end

      def week_number(day_of_period, day_of_week)
        # this should come from the CLDR's supplemental data set, but we
        # don't have access to it right now
        first_day_of_week = 1  # assume sunday
        minimal_days_in_first_week = 1  # assume US

        # Determine the day of the week of the first day of the period
        # in question (either a year or a month).  Zero represents the
        # first day of the week on this calendar.
        period_start_day_of_week = (day_of_week - first_day_of_week - day_of_period + 1) % 7

        if (period_start_day_of_week < 0)
          period_start_day_of_week += 7
        end

        # Compute the week number.  Initially, ignore the first week, which
        # may be fractional (or may not be).  We add period_start_day_of_week in
        # order to fill out the first week, if it is fractional.
        week_no = (day_of_period + period_start_day_of_week - 1) / 7

        # If the first week is long enough, then count it.  If
        # the minimal days in the first week is one, or if the period start
        # is zero, we always increment weekNo.
        if (7 - period_start_day_of_week) >= minimal_days_in_first_week
          week_no += 1
        end

        week_no
      end

      def week_data_cache
        @@week_data_cache ||= {}
      end

    end
  end
end
