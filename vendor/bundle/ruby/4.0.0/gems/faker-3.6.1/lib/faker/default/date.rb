# frozen_string_literal: true

module Faker
  class Date < Base
    DAYS_OF_WEEK = %i[sunday monday tuesday wednesday thursday friday saturday].freeze

    class << self
      ##
      # Produce a random date between two dates.
      #
      # @param from [Date, String] The start of the usable date range.
      # @param to [Date, String] The end of the usable date range.
      # @return [Date]
      #
      # @example if used with or without Rails (Active Support)
      #   Faker::Date.between(from: '2014-09-23', to: '2014-09-25') #=> #<Date: 2014-09-24>
      #
      # @example if used with Rails (Active Support)
      #   Faker::Date.between(from: 2.days.ago, to: Date.today) #=> #<Date: 2014-09-24>
      #
      # @faker.version 1.0.0
      def between(from:, to:)
        from = get_date_object(from)
        to   = get_date_object(to)

        Faker::Base.rand_in_range(from, to)
      end

      ##
      # Produce a random date between two dates.
      #
      # @param from [Date, String] The start of the usable date range.
      # @param to [Date, String] The end of the usable date range.
      # @param excepted [Date, String] A date to exclude.
      # @return [Date]
      #
      # @example if used with or without Rails (Active Support)
      #   Faker::Date.between_except(from: '2014-09-23', to: '2015-09-25', excepted: '2015-01-24') #=> #<Date: 2014-10-03>
      #
      # @example if used with Rails (Active Support)
      #   Faker::Date.between_except(from: 1.year.ago, to: 1.year.from_now, excepted: Date.today) #=> #<Date: 2014-10-03>
      #
      # @faker.version 1.6.2
      def between_except(from:, to:, excepted:)
        raise ArgumentError, 'From date, to date and excepted date must not be the same' if from == to && to == excepted

        excepted = get_date_object(excepted)

        loop do
          date = between(from: from, to: to)
          break date.to_date if date != excepted
        end
      end

      ##
      # Produce a random date in the future (up to N days).
      #
      # @param from [Integer] The start of the usable forward date range.
      # @param days [Integer] The maximum number of days to go into the future.
      # @return [Date]
      #
      # @example if used with or without Rails (Active Support)
      #   Faker::Date.forward(days: 23) #=> #<Date: 2014-10-03>
      #
      # @example if used with Rails (Active Support)
      #  Faker::Date.forward(from: Date.current, days: 17) #=> #<Date: 2022-06-22>
      #
      # @example if used with or without Rails (Active Support)
      #   Faker::Date.forward(from: '2022-06-03', days: 10) #=> #<Date: 2022-10-13>
      #
      # @faker.version 1.0.0
      def forward(from: ::Date.today, days: 365)
        start_date = get_date_object(from)
        since = start_date + 1
        to = start_date + days

        between(from: since, to: to).to_date
      end

      ##
      # Produce a random date in the past (up to N days).
      #
      # @param days [Integer] The maximum number of days to go into the past.
      # @return [Date]
      #
      # @example
      #   Faker::Date.backward(days: 14) #=> #<Date: 2019-09-12>
      #
      # @faker.version 1.0.0
      def backward(days: 365)
        from = ::Date.today - days
        to   = ::Date.today - 1

        between(from: from, to: to).to_date
      end

      ##
      # Produce a random date in the past (up to N days).
      #
      # @param min_age [Integer] The minimum age that the birthday would imply.
      # @param max_age [Integer] The maximum age that the birthday would imply.
      # @return [Date]
      #
      # @example
      #   Faker::Date.birthday(min_age: 18, max_age: 65) #=> #<Date: 1986-03-28>
      #
      # @faker.version 1.4.3
      def birthday(min_age: 18, max_age: 65)
        t = ::Date.today

        from = birthday_date(t, max_age)
        to   = birthday_date(t, min_age)

        between(from: from, to: to).to_date
      end

      ##
      # Produces a date in the year and/or month specified.
      #
      # @param month [Integer] represents the month of the date
      # @param year [Integer] represents the year of the date
      # @return [Date]
      #
      # @example
      #   Faker::Date.in_date_period #=> #<Date: 2019-09-01>
      #
      # @example
      #   Faker::Date.in_date_period(year: 2018, month: 2) #=> #<Date: 2018-02-26>
      #
      # @example
      #   Faker::Date.in_date_period(month: 2) #=> #<Date: 2019-02-26>
      #
      # @faker.version 2.13.0
      def in_date_period(month: nil, year: ::Date.today.year)
        from = ::Date.new(year, month || 1, 1)
        to = ::Date.new(year, month || 12, ::Date.civil(year, month || 12, -1).day)

        between(from: from, to: to).to_date
      end

      ##
      # Produce a random date at given day(s) of the week between two dates.
      #
      # @param day [Symbol, Array<Symbol>] # The day(s) of the week. See {DAYS_OF_WEEK}.
      # @param from [Date, String] The start of the usable date range.
      # @param to [Date, String] The end of the usable date range.
      # @return [Date]
      #
      # @example if used with or without Rails (Active Support)
      #   Faker::Date.on_day_of_week_between(day: :tuesday, from: '2023-01-01', to: '2023-02-01') #=> #<Date: 2032-01-10>
      #
      # @example if used with Rails (Active Support)
      #   Faker::Date.on_day_of_week_between(day: [:saturday, :sunday], from: 1.month.ago, to: Date.today) #=> #<Date: 2014-09-24>
      #
      # @faker.version next
      def on_day_of_week_between(day:, from:, to:)
        days = [day].flatten
        raise ArgumentError, 'Day of week cannot be empty' if days.empty?

        # Convert given days of the week to numbers used by `Date#wday` method
        numeric_weekdays = days.map do |d|
          DAYS_OF_WEEK.index(d.to_sym.downcase) || raise(ArgumentError, "#{d} is not a valid day of the week")
        end

        from = get_date_object(from)
        to   = get_date_object(to)
        date = Faker::Base.rand_in_range(from, to)

        # If the initial date is not on one of the wanted days of the week...
        unless numeric_weekdays.include? date.wday
          # ...pick a date nearby that is on one of the wanted days of the week instead
          date += sample(numeric_weekdays) - date.wday

          # Move date 1 week earlier or later if the adjusted date is now outside the date range
          date += 7 if date < from
          date -= 7 if date > to

          if date > to || date < from
            raise ArgumentError,
                  "There is no #{DAYS_OF_WEEK[date.wday].capitalize} between #{from} and #{to}. Increase the from/to date range or choose a different day of the week."
          end
        end

        date
      end

      private

      def birthday_date(date, age)
        year = date.year - age

        day =
          if date.day == 29 && date.month == 2 && !::Date.leap?(year)
            28
          else
            date.day
          end

        ::Date.new(year, date.month, day)
      end

      def get_date_object(date)
        date = ::Date.parse(date) if date.is_a?(::String)
        date = date.to_date if date.respond_to?(:to_date)
        date
      end
    end
  end
end
