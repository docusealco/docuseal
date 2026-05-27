# frozen_string_literal: true

require 'set'

module Aws
  module S3
    # @api private
    class AccessGrantsCredentials
      include CredentialProvider
      include RefreshingCredentials

      def initialize(options = {})
        @client = options[:client]
        @get_data_access_params = {}
        options.each_pair do |key, value|
          if self.class.get_data_access_options.include?(key)
            @get_data_access_params[key] = value
          end
        end
        @async_refresh = true
        super
      end

      # @return [S3Control::Client]
      attr_reader :client

      # @return [String]
      attr_reader :matched_grant_target

      private

      def refresh
        c = @client.get_data_access(@get_data_access_params)
        credentials = c.credentials
        @matched_grant_target = c.matched_grant_target
        @credentials = Credentials.new(
          credentials.access_key_id,
          credentials.secret_access_key,
          credentials.session_token
        )
        @expiration = credentials.expiration
      end

      class << self

        # @api private
        def get_data_access_options
          @gdao ||= begin
            input = Aws::S3Control::Client.api.operation(:get_data_access).input
            Set.new(input.shape.member_names)
          end
        end

      end
    end
  end
end
