# frozen_string_literal: true

class Pagy
  class Calendar
    class Week < Unit
      DEFAULT  = { order:  :asc,
                   format: '%Y-%W' }.freeze

      protected

      def assign_unit_variables
        super
        @initial = @starting.beginning_of_week
        @final   = @ending.next_week.beginning_of_week
        @last    = page_offset(@initial, @final)
        @from    = starting_time_for(@page)
        @to      = @from.next_week
      end

      def starting_time_for(page)
        @initial.weeks_since(time_offset_for(page))
      end

      def page_offset_at(time)
        page_offset(@initial, time.beginning_of_week)
      end

      private

      def page_offset(time_a, time_b)  # remove in 6.0
        (time_b.time - time_a.time).to_i / 1.week
      end
    end
  end
end
