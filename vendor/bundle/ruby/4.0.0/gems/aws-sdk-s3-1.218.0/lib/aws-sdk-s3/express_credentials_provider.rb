# frozen_string_literal: true

module Aws
  module S3
    # @api private
    def self.express_credentials_cache
      @express_credentials_cache ||= LRUCache.new(max_entries: 100)
    end

    # Returns Credentials class for S3 Express. Accepts CreateSession
    # params as options. See {Client#create_session} for details.
    class ExpressCredentialsProvider
      # @param [Hash] options
      # @option options [Client] :client The S3 client used to create the
      #  session.
      # @option options [String] :session_mode (see: {Client#create_session})
      # @option options [Boolean] :caching (true) When true, credentials will
      #  be cached.
      # @option options [Callable] :before_refresh Proc called before
      #   credentials are refreshed.
      def initialize(options = {})
        @client = options.delete(:client)
        @caching = options.delete(:caching) != false
        @options = options
        return unless @caching

        @cache = Aws::S3.express_credentials_cache
      end

      def express_credentials_for(bucket)
        if @caching
          cached_credentials_for(bucket)
        else
          new_credentials_for(bucket)
        end
      end

      attr_accessor :client

      private

      def cached_credentials_for(bucket)
        if @cache.key?(bucket)
          @cache[bucket]
        else
          @cache[bucket] = new_credentials_for(bucket)
        end
      end

      def new_credentials_for(bucket)
        ExpressCredentials.new(
          bucket: bucket,
          client: @client,
          **@options
        )
      end
    end
  end
end
