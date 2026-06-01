# frozen_string_literal: true

require 'set'

module Aws
  module S3
    # @api private
    class ExpressCredentials
      include CredentialProvider
      include RefreshingCredentials

      SYNC_EXPIRATION_LENGTH = 60 # 1 minute
      ASYNC_EXPIRATION_LENGTH = 120 # 2 minutes

      def initialize(options = {})
        @client = options[:client]
        @create_session_params = {}
        options.each_pair do |key, value|
          if self.class.create_session_options.include?(key)
            @create_session_params[key] = value
          end
        end
        @async_refresh = true
        super
      end

      # @return [S3::Client]
      attr_reader :client

      private

      def refresh
        c = @client.create_session(@create_session_params).credentials
        @credentials = Credentials.new(
          c.access_key_id,
          c.secret_access_key,
          c.session_token
        )
        @expiration = c.expiration
      end

      class << self

        # @api private
        def create_session_options
          @cso ||= begin
            input = S3::Client.api.operation(:create_session).input
            Set.new(input.shape.member_names)
          end
        end

      end
    end
  end
end
