# frozen_string_literal: true

require "rack"

module Sidekiq
  class Web
    # Provides an API to declare endpoints, along with a match
    # API to dynamically route a request to an endpoint.
    module Router
      def head(path, &) = route(:head, path, &)

      def get(path, &) = route(:get, path, &)

      def post(path, &) = route(:post, path, &)

      def put(path, &) = route(:put, path, &)

      def patch(path, &) = route(:patch, path, &)

      def delete(path, &) = route(:delete, path, &)

      def route(*methods, path, &block)
        methods.each do |method|
          raise ArgumentError, "Invalid method #{method}. Must be one of #{@routes.keys.join(",")}" unless route_cache.has_key?(method)
          route_cache[method] << Route.new(method, path, block)
        end
      end

      def match(env)
        request_method = env["REQUEST_METHOD"].downcase.to_sym
        path_info = ::Rack::Utils.unescape_path env["PATH_INFO"]

        # There are servers which send an empty string when requesting the root.
        # These servers should be ashamed of themselves.
        path_info = "/" if path_info == ""

        route_cache[request_method].each do |route|
          params = route.match(request_method, path_info)
          if params
            env["rack.route_params"] = params
            return Action.new(env, route.block)
          end
        end

        nil
      end

      def route_cache
        @@routes ||= {get: [], post: [], put: [], patch: [], delete: [], head: []}
      end
    end

    class Route
      attr_accessor :request_method, :pattern, :block, :name

      NAMED_SEGMENTS_PATTERN = /\/([^\/]*):([^.:$\/]+)/

      def initialize(request_method, pattern, block)
        @request_method = request_method
        @pattern = pattern
        @block = block
      end

      def matcher
        @matcher ||= compile
      end

      def compile
        if pattern.match?(NAMED_SEGMENTS_PATTERN)
          p = pattern.gsub(NAMED_SEGMENTS_PATTERN, '/\1(?<\2>[^$/]+)')

          Regexp.new("\\A#{p}\\Z")
        else
          pattern
        end
      end

      EMPTY = {}.freeze

      def match(request_method, path)
        case matcher
        when String
          EMPTY if path == matcher
        else
          path_match = path.match(matcher)
          path_match&.named_captures&.transform_keys(&:to_sym)
        end
      end
    end
  end
end
