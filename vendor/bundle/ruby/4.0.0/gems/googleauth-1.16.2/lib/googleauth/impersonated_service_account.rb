# Copyright 2024 Google, Inc.
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
require "googleauth/helpers/connection"

module Google
  module Auth
    # Authenticates requests using impersonation from base credentials.
    # This is a two-step process: first authentication claim from the base credentials is created
    # and then that claim is exchanged for a short-lived token at an IAMCredentials endpoint.
    # The short-lived token and its expiration time are cached.
    class ImpersonatedServiceAccountCredentials
      # @private
      CREDENTIAL_TYPE_NAME = "impersonated_service_account".freeze

      # @private
      ERROR_SUFFIX = <<~ERROR.freeze
        when trying to get security access token
        from IAM Credentials endpoint using the credentials provided.
      ERROR

      # @private
      IAM_SCOPE = ["https://www.googleapis.com/auth/iam".freeze].freeze

      # BaseClient most importantly implements the `:updater_proc` getter,
      # that returns a reference to an `apply!` method that updates
      # a hash argument provided with the authorization header containing
      # the access token (impersonation token in this case).
      include Google::Auth::BaseClient

      include Helpers::Connection

      # @return [Object] The original authenticated credentials used to fetch short-lived impersonation access tokens
      attr_reader :base_credentials

      # @return [Object] The modified version of base credentials, tailored for impersonation purposes
      #   with necessary scope adjustments
      attr_reader :source_credentials

      # @return [String] The URL endpoint used to generate an impersonation token. This URL should follow a specific
      #   format to specify the impersonated service account.
      attr_reader :impersonation_url

      # @return [Array<String>, String] The scope(s) required for the impersonated access token,
      #   indicating the permissions needed for the short-lived token
      attr_reader :scope

      # @return [String, nil] The short-lived impersonation access token, retrieved and cached
      #   after making the impersonation request
      attr_reader :access_token

      # @return [Time, nil] The expiration time of the current access token, used to determine
      #   if the token is still valid
      attr_reader :expires_at

      # Create a ImpersonatedServiceAccountCredentials
      # When you use service account impersonation, you start with an authenticated principal
      # (e.g. your user account or a service account)
      # and request short-lived credentials for a service account
      # that has the authorization that your use case requires.
      #
      # @note Warning:
      # This method does not validate the credential configuration. A security
      # risk occurs when a credential configuration configured with malicious urls
      # is used.
      # When the credential configuration is accepted from an
      # untrusted source, you should validate it before using with this method.
      # See https://cloud.google.com/docs/authentication/external/externally-sourced-credentials
      # for more details.
      #
      # @param options [Hash] A hash of options to configure the credentials.
      # @option options [Object] :base_credentials (required) The authenticated principal.
      #   It will be used as following:
      #   * will be duplicated (with IAM scope) to create the source credentials if it supports duplication
      #   * as source credentials otherwise.
      # @option options [String] :impersonation_url (required) The URL to impersonate the service account.
      #   This URL should follow the format:
      #   `https://iamcredentials.{universe_domain}/v1/projects/-/serviceAccounts/{source_sa_email}:generateAccessToken`,
      #   where:
      #     - `{universe_domain}` is the domain of the IAMCredentials API endpoint (e.g., `googleapis.com`).
      #     - `{source_sa_email}` is the email address of the service account to impersonate.
      # @option options [Array<String>, String] :scope (required) The scope(s) for the short-lived impersonation token,
      #   defining the permissions required for the token.
      # @option options [Object] :source_credentials The authenticated principal that will be used
      #   to fetch the short-lived impersonation access token. It is an alternative to providing the base credentials.
      # @option options [IO] :json_key_io The IO object that contains the credential configuration.
      #   It is exclusive with `:base_credentials` and `:source_credentials` options.
      #
      # @return [Google::Auth::ImpersonatedServiceAccountCredentials]
      def self.make_creds options = {}
        if options[:json_key_io]
          make_creds_from_json options
        else
          new options
        end
      end

      # @private
      def self.make_creds_from_json options
        json_key_io = options[:json_key_io]
        if options[:base_credentials] || options[:source_credentials]
          raise Google::Auth::InitializationError,
                "json_key_io is not compatible with base_credentials or source_credentials"
        end

        require "googleauth/default_credentials"
        impersonated_json = MultiJson.load json_key_io.read
        source_credentials_info = impersonated_json["source_credentials"]

        if source_credentials_info["type"] == CREDENTIAL_TYPE_NAME
          raise Google::Auth::InitializationError,
                "Source credentials can't be of type impersonated_service_account, " \
                "use delegates to chain impersonation."
        end

        source_credentials = DefaultCredentials.make_creds(
          json_key_io: StringIO.new(MultiJson.dump(source_credentials_info))
        )

        impersonation_url = impersonated_json["service_account_impersonation_url"]
        scope = options[:scope] || impersonated_json["scopes"]

        new(
          source_credentials: source_credentials,
          impersonation_url:  impersonation_url,
          scope:              scope
        )
      end
      private_class_method :make_creds_from_json

      # Initializes a new instance of ImpersonatedServiceAccountCredentials.
      #
      # @param options [Hash] A hash of options to configure the credentials.
      # @option options [Object] :base_credentials (required) The authenticated principal.
      #   It will be used as following:
      #   * will be duplicated (with IAM scope) to create the source credentials if it supports duplication
      #   * as source credentials otherwise.
      # @option options [String] :impersonation_url (required) The URL to impersonate the service account.
      #   This URL should follow the format:
      #   `https://iamcredentials.{universe_domain}/v1/projects/-/serviceAccounts/{source_sa_email}:generateAccessToken`,
      #   where:
      #     - `{universe_domain}` is the domain of the IAMCredentials API endpoint (e.g., `googleapis.com`).
      #     - `{source_sa_email}` is the email address of the service account to impersonate.
      # @option options [Array<String>, String] :scope (required) The scope(s) for the short-lived impersonation token,
      #   defining the permissions required for the token.
      #   It will override the scope from the `json_key_io` file if provided.
      # @option options [Object] :source_credentials The authenticated principal that will be used
      #   to fetch the short-lived impersonation access token. It is an alternative to providing the base credentials.
      #   It is redundant to provide both source and base credentials as only source will be used,
      #   but it can be done, e.g. when duplicating existing credentials.
      #
      # @raise [ArgumentError] If any of the required options are missing.
      #
      # @return [Google::Auth::ImpersonatedServiceAccountCredentials]
      def initialize options = {}
        @base_credentials, @impersonation_url, @scope =
          options.values_at :base_credentials,
                            :impersonation_url,
                            :scope

        # Fail-fast checks for required parameters
        if @base_credentials.nil? && !options.key?(:source_credentials)
          raise ArgumentError, "Missing required option: either :base_credentials or :source_credentials"
        end
        raise ArgumentError, "Missing required option: :impersonation_url" if @impersonation_url.nil?
        raise ArgumentError, "Missing required option: :scope" if @scope.nil?

        # Some credentials (all Signet-based ones and this one) include scope and a bunch of transient state
        # (e.g. refresh status) as part of themselves
        # so a copy needs to be created with the scope overriden and transient state dropped.
        #
        # If a credentials does not support `duplicate` we'll try to use it as is assuming it has a broad enough scope.
        # This might result in an "access denied" error downstream when the token from that credentials is being used
        # for the token exchange.
        @source_credentials = if options.key? :source_credentials
                                options[:source_credentials]
                              elsif @base_credentials.respond_to? :duplicate
                                @base_credentials.duplicate({
                                                              scope: IAM_SCOPE
                                                            })
                              else
                                @base_credentials
                              end
      end

      # Determines whether the current access token expires within the specified number of seconds.
      #
      # @param seconds [Integer] The number of seconds to check against the token's expiration time.
      #
      # @return [Boolean] Whether the access token expires within the given time frame
      def expires_within? seconds
        # This method is needed for BaseClient
        @expires_at && @expires_at - Time.now.utc < seconds
      end

      # The universe domain of the impersonated credentials.
      # Effectively this retrieves the universe domain of the source credentials.
      #
      # @return [String] The universe domain of the credentials.
      def universe_domain
        @source_credentials.universe_domain
      end

      # @return [Logger, nil] The logger of the credentials.
      def logger
        @source_credentials.logger if source_credentials.respond_to? :logger
      end

      # Creates a duplicate of these credentials without transient token state
      #
      # @param options [Hash] Overrides for the credentials parameters.
      #   The following keys are recognized
      #   * `base_credentials` the base credentials used to initialize the impersonation
      #   * `source_credentials` the authenticated credentials which usually would be
      #     base credentials with scope overridden to IAM_SCOPE
      #   * `impersonation_url` the URL to use to make an impersonation token exchange
      #   * `scope` the scope(s) to access
      #
      # @return [Google::Auth::ImpersonatedServiceAccountCredentials]
      def duplicate options = {}
        options = deep_hash_normalize options

        options = {
          base_credentials: @base_credentials,
          source_credentials: @source_credentials,
          impersonation_url: @impersonation_url,
          scope: @scope
        }.merge(options)

        self.class.new options
      end

      # The principal behind the credentials. This class allows custom source credentials type
      # that might not implement `principal`, in which case `:unknown` is returned.
      #
      # @private
      # @return [String, Symbol] The string representation of the principal,
      #     the token type in lieu of the principal, or :unknown if source principal is unknown.
      def principal
        if @source_credentials.respond_to? :principal
          @source_credentials.principal
        else
          :unknown
        end
      end

      private

      # Generates a new impersonation access token by exchanging the source credentials' token
      # at the impersonation URL.
      #
      # This method first fetches an access token from the source credentials and then exchanges it
      # for an impersonation token using the specified impersonation URL. The generated token and
      # its expiration time are cached for subsequent use.
      #
      # @private
      # @param _options [Hash] (optional) Additional options for token retrieval (currently unused).
      #
      # @raise [Google::Auth::UnexpectedStatusError] If the response status is 403 or 500.
      # @raise [Google::Auth::AuthorizationError] For other unexpected response statuses.
      #
      # @return [String] The newly generated impersonation access token.
      def fetch_access_token! _options = {}
        auth_header = prepare_auth_header
        resp = make_impersonation_request auth_header

        case resp.status
        when 200
          response = MultiJson.load resp.body
          self.expires_at = response["expireTime"]
          @access_token = response["accessToken"]
          access_token
        when 403, 500
          handle_error_response resp, UnexpectedStatusError
        else
          handle_error_response resp, AuthorizationError
        end
      end

      # Prepares the authorization header for the impersonation request
      # by fetching a token from source credentials.
      #
      # @private
      # @return [Hash] The authorization header with the source credentials' token
      def prepare_auth_header
        auth_header = {}
        @source_credentials.updater_proc.call auth_header
        auth_header
      end

      # Makes the HTTP request to the impersonation endpoint.
      #
      # @private
      # @param [Hash] auth_header The authorization header containing the source token
      # @return [Faraday::Response] The HTTP response from the impersonation endpoint
      def make_impersonation_request auth_header
        connection.post @impersonation_url do |req|
          req.headers.merge! auth_header
          req.headers["Content-Type"] = "application/json"
          req.body = MultiJson.dump({ scope: @scope })
        end
      end

      # Creates and raises an appropriate error based on the response.
      #
      # @private
      # @param [Faraday::Response] resp The HTTP response
      # @param [Class] error_class The error class to instantiate
      # @raise [StandardError] The appropriate error with details
      def handle_error_response resp, error_class
        msg = "Unexpected error code #{resp.status}.\n #{resp.env.response_body} #{ERROR_SUFFIX}"
        raise error_class.with_details(
          msg,
          credential_type_name: self.class.name,
          principal: principal
        )
      end

      # Setter for the expires_at value that makes sure it is converted
      # to Time object.
      def expires_at= new_expires_at
        @expires_at = normalize_timestamp new_expires_at
      end

      # Returns the type of token (access_token).
      # This method is needed for BaseClient.
      def token_type
        :access_token
      end

      # Normalizes a timestamp to a Time object.
      #
      # @param time [Time, String, nil] The timestamp to normalize.
      #
      # @return [Time, nil] The normalized Time object, or nil if the input is nil.
      #
      # @raise [Google::Auth::CredentialsError] If the input is not a Time, String, or nil.
      def normalize_timestamp time
        case time
        when NilClass
          nil
        when Time
          time
        when String
          Time.parse time
        else
          message = "Invalid time value #{time}"
          raise CredentialsError.with_details(message, credential_type_name: self.class.name, principal: principal)
        end
      end

      # Convert all keys in this hash (nested) to symbols for uniform retrieval
      def recursive_hash_normalize_keys val
        if val.is_a? Hash
          deep_hash_normalize val
        else
          val
        end
      end

      def deep_hash_normalize old_hash
        sym_hash = {}
        old_hash&.each { |k, v| sym_hash[k.to_sym] = recursive_hash_normalize_keys v }
        sym_hash
      end
    end
  end
end
