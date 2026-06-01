# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "googleauth/base_client"
require "googleauth/errors"

module Google
  module Auth
    ##
    # Implementation of Bearer Token authentication scenario.
    #
    # Bearer tokens are strings representing an authorization grant.
    # They can be OAuth2 ("ya.29") tokens, JWTs, IDTokens -- anything
    # that is sent as a `Bearer` in an `Authorization` header.
    #
    # Not all 'authentication' strings can be used with this class,
    # e.g. an API key cannot since API keys are sent in a
    # `x-goog-api-key` header or as a query parameter.
    #
    # This class should be used when the end-user is managing the
    # authentication token separately, e.g. with a separate service.
    # This means that tasks like tracking the lifetime of and
    # refreshing the token are outside the scope of this class.
    #
    # There is no JSON representation for this type of credentials.
    # If the end-user has credentials in JSON format they should typically
    # use the corresponding credentials type, e.g. ServiceAccountCredentials
    # with the service account JSON.
    #
    class BearerTokenCredentials
      include Google::Auth::BaseClient

      # @private Authorization header name
      AUTH_METADATA_KEY = Google::Auth::BaseClient::AUTH_METADATA_KEY

      # @return [String] The token to be sent as a part of Bearer claim
      attr_reader :token
      # The following aliasing is needed for BaseClient since it sends :token_type
      alias bearer_token token

      # @return [Time, nil] The token expiration time provided by the end-user.
      attr_reader :expires_at

      # @return [String] The universe domain of the universe
      #   this token is for
      attr_accessor :universe_domain

      class << self
        # Create the BearerTokenCredentials.
        #
        # @param [Hash] options The credentials options
        # @option options [String] :token The bearer token to use.
        # @option options [Time, Numeric, nil] :expires_at The token expiration time provided by the end-user.
        #   Optional, for the end-user's convenience. Can be a Time object, a number of seconds since epoch.
        #   If `expires_at` is `nil`, it is treated as "token never expires".
        # @option options [String] :universe_domain The universe domain of the universe
        #   this token is for (defaults to googleapis.com)
        # @return [Google::Auth::BearerTokenCredentials]
        def make_creds options = {}
          new options
        end
      end

      # Initialize the BearerTokenCredentials.
      #
      # @param [Hash] options The credentials options
      # @option options [String] :token The bearer token to use.
      # @option options [Time, Numeric, nil] :expires_at The token expiration time provided by the end-user.
      #   Optional, for the end-user's convenience. Can be a Time object, a number of seconds since epoch.
      #   If `expires_at` is `nil`, it is treated as "token never expires".
      # @option options [String] :universe_domain The universe domain of the universe
      #   this token is for (defaults to googleapis.com)
      # @raise [ArgumentError] If the bearer token is nil or empty
      def initialize options = {}
        raise ArgumentError, "Bearer token must be provided" if options[:token].nil? || options[:token].empty?
        @token = options[:token]
        @expires_at = case options[:expires_at]
                      when Time
                        options[:expires_at]
                      when Numeric
                        Time.at options[:expires_at]
                      end

        @universe_domain = options[:universe_domain] || "googleapis.com"
      end

      # Determines if the credentials object has expired.
      #
      # @param [Numeric] seconds The optional timeout in seconds.
      # @return [Boolean] True if the token has expired, false otherwise, or
      #   if the expires_at was not provided.
      def expires_within? seconds
        return false if @expires_at.nil? # Treat nil expiration as "never expires"
        Time.now + seconds >= @expires_at
      end

      # Creates a duplicate of these credentials.
      #
      # @param [Hash] options Additional options for configuring the credentials
      # @option options [String] :token The bearer token to use.
      # @option options [Time, Numeric] :expires_at The token expiration time. Can be a Time
      #   object or a number of seconds since epoch.
      # @option options [String] :universe_domain The universe domain (defaults to googleapis.com)
      # @return [Google::Auth::BearerTokenCredentials]
      def duplicate options = {}
        self.class.new(
          token: options[:token] || @token,
          expires_at: options[:expires_at] || @expires_at,
          universe_domain: options[:universe_domain] || @universe_domain
        )
      end

      # For credentials that are initialized with a token without a principal,
      # the type of that token should be returned as a principal instead
      # @private
      # @return [Symbol] the token type in lieu of the principal
      def principal
        token_type
      end

      protected

      ##
      # BearerTokenCredentials do not support fetching a new token.
      #
      # If the token has an expiration time and is expired, this method will
      # raise an error.
      #
      # @param [Hash] _options Options for fetching a new token (not used).
      # @return [nil] Always returns nil.
      # @raise [Google::Auth::CredentialsError] If the token is expired.
      def fetch_access_token! _options = {}
        if @expires_at && Time.now >= @expires_at
          raise CredentialsError.with_details(
            "Bearer token has expired.",
            credential_type_name: self.class.name,
            principal: principal
          )
        end

        nil
      end

      private

      def token_type
        :bearer_token
      end
    end
  end
end
