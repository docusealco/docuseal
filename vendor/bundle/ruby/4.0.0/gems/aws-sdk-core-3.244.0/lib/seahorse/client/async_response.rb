# frozen_string_literal: true

module Seahorse
  module Client
    class AsyncResponse

      def initialize(options = {})
        @response = Response.new(context: options[:context])
        @stream = options[:stream]
        @stream_mutex = options[:stream_mutex]
        @close_condition = options[:close_condition]
        @sync_queue = options[:sync_queue]
      end

      # @return [RequestContext]
      def context
        @response.context
      end

      # @return [StandardError, nil]
      def error
        @response.error
      end

      # @overload on(status_code, &block)
      #   @param [Integer] status_code The block will be
      #     triggered only for responses with the given status code.
      #
      # @overload on(status_code_range, &block)
      #   @param [Range<Integer>] status_code_range The block will be
      #     triggered only for responses with a status code that falls
      #     witin the given range.
      #
      # @return [self]
      def on(range, &block)
        @response.on(range, &block)
        self
      end

      # @api private
      def on_complete(&block)
        @response.on_complete(&block)
        self
      end

      # @return [Boolean] Returns `true` if the response is complete with
      #   no error.
      def successful?
        @response.error.nil?
      end

      def wait
        if error && context.config.raise_response_errors
          raise error
        elsif @stream
          # have a sync signal that #signal can be blocked on
          # else, if #signal is called before #wait
          # will be waiting for a signal never arrives
          @sync_queue << "sync_signal"
          # now #signal is unlocked for
          # signaling close condition when ready
          @stream_mutex.synchronize {
            @close_condition.wait(@stream_mutex)
          }
          @response
        end
      end

      def join!
        if error && context.config.raise_response_errors
          raise error
        elsif @stream
          # close callback is waiting
          # for the "sync_signal"
          @sync_queue << "sync_signal"
          @stream.close
          @response
        end
      end

    end
  end
end
