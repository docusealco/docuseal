# frozen_string_literal: true

class Pagy # :nodoc:
  class Calendar # :nodoc:
    class Month < Unit
      DEFAULT = { slots:   12,
                  compact: true,
                  order:   :asc,
                  format:  '%b' }.freeze

      protected

      def assign_unit_variables
        super
        @initial = @starting.beginning_of_month
        @final   = @ending.next_month.beginning_of_month
        @last    = (months_in(@final) - months_in(@initial))
        @from    = starting_time_for(@page)
        @to      = @from.next_month
      end

      def starting_time_for(page)
        @initial.months_since(time_offset_for(page))
      end

      def page_offset_at(time)
        months_in(time.beginning_of_month) - months_in(@initial)
      end

      private

      def months_in(time)
        (time.year * 12) + time.month
      end
    end
  end
end
