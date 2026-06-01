# frozen_string_literal: true

module Ferrum
  class Browser
    class Options
      attr_writer :window_size
      attr_accessor :url_blacklist, :url_whitelist

      def reset_window_size
        @window_size = @options[:window_size]
      end
    end
  end
end
