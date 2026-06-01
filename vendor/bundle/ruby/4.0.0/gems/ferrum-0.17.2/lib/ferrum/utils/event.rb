# frozen_string_literal: true

module Ferrum
  module Utils
    class Event < Concurrent::Event
      def iteration
        synchronize { @iteration }
      end

      def reset
        synchronize do
          @iteration += 1
          @set = false if @set
          @iteration
        end
      end
    end
  end
end
