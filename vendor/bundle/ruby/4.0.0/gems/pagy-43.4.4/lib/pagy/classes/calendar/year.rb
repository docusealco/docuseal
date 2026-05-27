# frozen_string_literal: true

class Pagy # :nodoc:
  class Calendar # :nodoc:
    # Year unit subclass
    class Year < Unit
      DEFAULT = { slots:   10,
                  compact: true,
                  order:   :asc,
                  format:  '%Y' }.freeze

      protected

      # Set up the calendar variables
      def assign_unit_variables
        super
        @initial = @starting.beginning_of_year
        @final   = @ending.next_year.beginning_of_year
        @last    = @final.year - @initial.year
        @from    = starting_time_for(@page)
        @to      = @from.next_year
      end

      # Starting time for the page
      def starting_time_for(page)
        @initial.years_since(time_offset_for(page))
      end

      def page_offset_at(time)
        time.beginning_of_year.year - @initial.year
      end
    end
  end
end
