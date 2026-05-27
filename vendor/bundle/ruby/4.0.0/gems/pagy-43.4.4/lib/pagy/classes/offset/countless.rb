# frozen_string_literal: true

class Pagy
  class Offset
    # Offset pagination without a count
    class Countless < Offset
      def initialize(**)
        assign_options(**)
        assign_and_check(limit: 1, page: 1)
        @page = upto_max_pages(@page)
        @last = upto_max_pages(@options[:last]) unless @options[:headless]
        assign_offset
      end

      def records(collection)
        return super if @options[:headless]

        fetched = collection.offset(@offset).limit(@limit + 1).to_a # eager load limit + 1
        finalize(fetched.size)                                      # finalize the pagy object
        fetched[0, @limit]                                          # ignore the extra item
      end

      protected

      def countless? = true

      def upto_max_pages(value)
        return value unless value && @options[:max_pages]

        [value, @options[:max_pages]].min
      end

      # Finalize the instance variables based on the fetched size
      def finalize(fetched_size)
        # empty records (trigger the right info message for known 0 count)
        @count = 0 if fetched_size.zero? && @page == 1

        unless in_range? { fetched_size.positive? || @page == 1 }
          assign_empty_page_variables
          return self
        end

        past  = @last && @page < @last # current page is before the known last page
        more  = fetched_size > @limit  # more pages after this one
        @last = upto_max_pages(more ? @page + 1 : @page) unless past && more
        @in   = [fetched_size, @limit].min
        @from = @in.zero? ? 0 : @offset + 1
        @to   = @offset + @in
        assign_previous_and_next

        self
      end

      # Called by false in_range?
      def assign_empty_page_variables
        @in = @from = @to = 0
        target_last = [@page - 1, 1].max
        @last       = [@last || target_last, target_last].min
        @previous   = @last
      end

      # Support easy countless page param overriding (for legacy param and behavior)
      def compose_page_param(page)
        EscapedValue.new("#{page || 1}+#{@last}")
      end
    end
  end
end
