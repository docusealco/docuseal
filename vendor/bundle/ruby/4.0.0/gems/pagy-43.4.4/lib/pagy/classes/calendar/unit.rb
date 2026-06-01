# frozen_string_literal: true

require_relative '../../modules/abilities/shiftable'
require_relative '../../modules/abilities/rangeable'

class Pagy
  class Calendar
    # Base class for time units subclasses (Year, Quarter, Month, Week, Day)
    #
    # To define a "bimester" unit you should:
    # - Define a `Pagy::Calendar::Bimester` class
    # - Add the `:bimester` unit symbol in the `Pagy::Calendar::UNITS`
    # - Ensure the desc duration order of the UNITS (i.e. insert it between `:quarter` and `:month`)
    class Unit < Pagy
      DEFAULT = { page: 1 }.freeze

      include Rangeable
      include Shiftable
      include NumericHelpers

      def initialize(**)
        assign_options(**)
        assign_and_check(page: 1)
        assign_unit_variables
        unless in_range? { @page <= @last }
          assign_empty_page_variables
          return
        end

        assign_previous_and_next
      end

      attr_reader :order, :from, :to, :previous, :last
      alias pages last

      protected

      def calendar? = true

      # Called by false in_range?
      def assign_empty_page_variables
        @in = @from = @to = 0                        # options relative to the actual page
        edge = @order == :asc ? @final : @initial    # get the edge of the range (neat, but any time would do)
        @from = @to = edge                           # set both to the edge time (a >=&&< query will get no records)
        @previous = @last
      end

      # The page that includes time
      # In case of time out of range, the :fit_time option avoids the RangeError
      # and returns the closest page to the passed time argument (first or last page)
      def page_at(time, **options)
        fit_time  = time
        fit_final = @final - 1
        unless time.between?(@initial, fit_final)
          raise RangeError.new(self, :time, "between #{@initial} and #{fit_final}", time) unless options[:fit_time]

          fit_time = time < @final ? @initial : fit_final
        end
        offset = page_offset_at(fit_time)   # offset starts from 0
        @order == :asc ? offset + 1 : @last - offset
      end

      # Base class method for the setup of the unit variables (subclasses must implement it and call super)
      def assign_unit_variables
        @order = @options[:order]
        @starting, @ending = @options[:period]
        raise OptionError.new(self, :period, 'to be an Array of min and max TimeWithZone instances', @options[:period]) \
              unless @starting.is_a?(ActiveSupport::TimeWithZone) \
                  && @ending.is_a?(ActiveSupport::TimeWithZone) && @starting <= @ending
      end

      # Apply the strftime format to the time.
      # Localization other than :en, requires the rails-I18n gem.
      def localize(time, **options)
        # Impossible to "unprepend" the rails-i18n after it runs localize_with_rails_i18n_gem in test
        # :nocov:
        time.strftime(options[:format])
        # :nocov:
      end

      # The number of time units to offset from the @initial time, in order to get the ordered starting time for the page.
      # Used in starting_time_for(page) where page starts from 1 (e.g. page to starting_time means subtracting 1)
      def time_offset_for(page)
        @order == :asc ? page - 1 : @last - page
      end

      # Period of the active page (used internally for nested units)
      def active_period
        [[@starting, @from].max, [@to - 1, @ending].min] # -1 sec: include only last unit day
      end
    end
  end
end
