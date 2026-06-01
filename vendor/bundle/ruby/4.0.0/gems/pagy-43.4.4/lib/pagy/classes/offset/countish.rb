# frozen_string_literal: true

class Pagy
  class Offset
    # Offset pagination with memoized count
    class Countish < Offset
      protected

      # Return page+count or page+count+epoch
      def compose_page_param(page)
        value  = "#{page || 1}+#{@count}"
        value << "+#{@options[:epoch]}" if @options[:epoch]
        EscapedValue.new(value)
      end
    end
  end
end
