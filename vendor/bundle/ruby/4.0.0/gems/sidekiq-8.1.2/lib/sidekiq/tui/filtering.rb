module Sidekiq
  class TUI
    module Filtering
      def filtering?
        @data[:filtering]
      end

      def current_filter
        @data[:filter]
      end

      def start_filtering
        @data[:filtering] = true
        @data[:filter] = ""
      end

      def stop_filtering
        return unless @data[:filtering]

        @data[:filtering] = false
        @data[:selected] = []
      end

      def stop_and_clear_filtering
        return unless @data[:filtering]

        @data[:filtering] = false
        @data[:filter] = nil
        @data[:selected] = []
        on_filter_change
      end

      def remove_last_char_from_filter
        return unless @data[:filtering]

        @data[:filter] = @data[:filter].empty? ? "" : @data[:filter][0..-2]
        on_filter_change
      end

      def append_to_filter(string)
        return unless @data[:filtering]

        @data[:filter] += string
        @data[:selected] = []
        on_filter_change
      end

      def on_filter_change
        # callback for subclasses
      end
    end
  end
end
