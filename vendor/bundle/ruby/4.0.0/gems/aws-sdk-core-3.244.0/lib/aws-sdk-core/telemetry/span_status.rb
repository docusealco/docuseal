# frozen_string_literal: true

module Aws
  module Telemetry
    # Represents the status of a finished span.
    class SpanStatus
      class << self
        private :new

        # Returns a newly created {SpanStatus} with code, `UNSET`
        # and an optional description.
        #
        # @param [optional String] description
        # @return [SpanStatus]
        def unset(description = '')
          new(UNSET, description: description)
        end

        # Returns a newly created {SpanStatus} with code, `OK`
        # and an optional description.
        #
        # @param [optional String] description
        # @return [SpanStatus]
        def ok(description = '')
          new(OK, description: description)
        end

        # Returns a newly created {SpanStatus} with code, `ERROR`
        # and an optional description.
        #
        # @param [optional String] description
        # @return [SpanStatus]
        def error(description = '')
          new(ERROR, description: description)
        end
      end

      def initialize(code, description: '')
        @code = code
        @description = description
      end

      # @return [Integer] code
      attr_reader :code

      # @return [String] description
      attr_reader :description

      # The operation completed successfully.
      OK = 0

      # The default status.
      UNSET = 1

      # An error.
      ERROR = 2
    end
  end
end
