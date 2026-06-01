# frozen_string_literal: true

module Aws
  module Plugins
    module Retries
      # @api private
      class ClockSkew
        CLOCK_SKEW_THRESHOLD = 5 * 60 # five minutes

        def initialize
          @mutex = Mutex.new
          # clock_corrections are recorded only on errors
          # and only when time difference is greater than the
          # CLOCK_SKEW_THRESHOLD
          @endpoint_clock_corrections = Hash.new(0)

          # estimated_skew is calculated on every request
          # and is used to estimate a TTL for requests
          @endpoint_estimated_skews = Hash.new(nil)
        end

        # Gets the clock_correction in seconds to apply to a given endpoint
        # @param endpoint [URI, String]
        def clock_correction(endpoint)
          @mutex.synchronize { @endpoint_clock_corrections[normalized_endpoint(endpoint)] }
        end

        # The estimated skew factors in any clock skew from
        # the service along with any network latency.
        # This provides a more accurate value for the ttl,
        # which should represent when the client will stop
        # waiting for a request.
        # Estimated Skew should not be used to correct clock skew errors
        # it should only be used to estimate TTL for a request
        def estimated_skew(endpoint)
          @mutex.synchronize { @endpoint_estimated_skews[normalized_endpoint(endpoint)] }
        end

        # Determines whether a request has clock skew by comparing
        # the current time against the server's time in the response
        # @param context [Seahorse::Client::RequestContext]
        def clock_skewed?(context)
          server_time = server_time(context.http_response)
          !!server_time &&
            (Time.now.utc - server_time).abs > CLOCK_SKEW_THRESHOLD
        end

        # Called only on clock skew related errors
        # Update the stored clock skew correction value for an endpoint
        # from the server's time in the response
        # @param context [Seahorse::Client::RequestContext]
        def update_clock_correction(context)
          endpoint = context.http_request.endpoint
          now_utc = Time.now.utc
          server_time = server_time(context.http_response)
          return unless server_time && (now_utc - server_time).abs > CLOCK_SKEW_THRESHOLD

          set_clock_correction(normalized_endpoint(endpoint), server_time - now_utc)
        end

        # Called for every request
        # Update our estimated clock skew for the endpoint
        # from the servers time in the response
        # @param context [Seahorse::Client::RequestContext]
        def update_estimated_skew(context)
          endpoint = context.http_request.endpoint
          now_utc = Time.now.utc
          server_time = server_time(context.http_response)
          return unless server_time

          @mutex.synchronize do
            @endpoint_estimated_skews[normalized_endpoint(endpoint)] = server_time - now_utc
          end
        end

        private

        ##
        # @param endpoint [URI, String]
        #     the endpoint to normalize
        #
        # @return [String]
        #     the endpoint's schema, host, and port - without any path or query arguments
        def normalized_endpoint(endpoint)
          uri = endpoint.is_a?(URI::Generic) ? endpoint : URI(endpoint.to_s)

          return endpoint.to_s unless uri.scheme && uri.host

          "#{uri.scheme}://#{uri.host}:#{uri.port}"
        rescue URI::InvalidURIError
          endpoint.to_s
        end

        # @param response [Seahorse::Client::Http::Response:]
        def server_time(response)
          Time.parse(response.headers['date']).utc
        rescue StandardError
          nil
        end

        # Sets the clock correction for an endpoint
        # @param endpoint [URI / String]
        # @param correction [Number]
        def set_clock_correction(endpoint, correction)
          @mutex.synchronize do
            @endpoint_clock_corrections[normalized_endpoint(endpoint)] = correction
          end
        end
      end
    end
  end
end
