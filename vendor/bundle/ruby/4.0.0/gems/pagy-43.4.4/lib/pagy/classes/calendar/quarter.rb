# frozen_string_literal: true

class Pagy # :nodoc:
  class Calendar # :nodoc:
    class Quarter < Unit
      DEFAULT = { slots:   4,
                  compact: true,
                  order:   :asc,
                  format:  'Q%q' }.freeze # '%q' token

      protected

      # The label for any page, with the substitution of the '%q' token
      def page_label(page, **options)
        starting_time = starting_time_for(page.to_i)  # page could be a string
        options[:format] = (options[:format] || @options[:format]).gsub('%q') { (starting_time.month / 3.0).ceil }
        localize(starting_time, **options)
      end

      def assign_unit_variables
        super
        @initial = @starting.beginning_of_quarter
        @final   = @ending.next_quarter.beginning_of_quarter
        @last    = (months_in(@final) - months_in(@initial)) / 3
        @from    = starting_time_for(@page)
        @to      = @from.next_quarter
      end

      def starting_time_for(page)
        @initial.months_since(time_offset_for(page) * 3)
      end

      def page_offset_at(time)
        (months_in(time.beginning_of_quarter) - months_in(@initial)) / 3
      end

      private

      def months_in(time)
        (time.year * 12) + time.month
      end
    end
  end
end
