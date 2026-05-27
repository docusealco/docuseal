# Copyright 2015 Google, Inc.
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

require "jwt"
require "multi_json"
require "stringio"

require "google/logging/message"
require "googleauth/signet"
require "googleauth/credentials_loader"
require "googleauth/json_key_reader"
require "googleauth/service_account_jwt_header"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    # Authenticates requests using Google's Service Account credentials via an
    # OAuth access token.
    #
    # This class allows authorizing requests for service accounts directly
    # from credentials from a json key file downloaded from the developer
    # console (via 'Generate new Json Key').
    #
    # cf [Application Default Credentials](https://cloud.google.com/docs/authentication/production)
    class ServiceAccountCredentials < Signet::OAuth2::Client
      TOKEN_CRED_URI = "https://www.googleapis.com/oauth2/v4/token".freeze
      extend CredentialsLoader
      extend JsonKeyReader
      attr_reader :project_id
      attr_reader :quota_project_id

      # @private
      # @type [::String] The type name for this credential.
      CREDENTIAL_TYPE_NAME = "service_account".freeze

      def enable_self_signed_jwt?
        # Use a self-singed JWT if there's no information that can be used to
        # obtain an OAuth token, OR if there are scopes but also an assertion
        # that they are default scopes that shouldn't be used to fetch a token,
        # OR we are not in the default universe and thus OAuth isn't supported.
        target_audience.nil? && (scope.nil? || @enable_self_signed_jwt || universe_domain != "googleapis.com")
      end

      # Creates a ServiceAccountCredentials.
      #
      # @param json_key_io [IO] An IO object containing the JSON key
      # @param scope [string|array|nil] the scope(s) to access
      # @raise [ArgumentError] If both scope and target_audience are specified
      def self.make_creds options = {} # rubocop:disable Metrics/MethodLength
        json_key_io, scope, enable_self_signed_jwt, target_audience, audience, token_credential_uri =
          options.values_at :json_key_io, :scope, :enable_self_signed_jwt, :target_audience,
                            :audience, :token_credential_uri
        raise ArgumentError, "Cannot specify both scope and target_audience" if scope && target_audience

        private_key, client_email, project_id, quota_project_id, universe_domain =
          if json_key_io
            json_key = MultiJson.load json_key_io.read
            if json_key.key? "type"
              json_key_io.rewind
            else # Defaults to class credential 'type' if missing.
              json_key["type"] = CREDENTIAL_TYPE_NAME
              json_key_io = StringIO.new MultiJson.dump(json_key)
            end
            CredentialsLoader.load_and_verify_json_key_type json_key_io, CREDENTIAL_TYPE_NAME
            read_json_key json_key_io
          else
            creds_from_env
          end
        project_id ||= CredentialsLoader.load_gcloud_project_id

        new(token_credential_uri:   token_credential_uri || TOKEN_CRED_URI,
            audience:               audience || TOKEN_CRED_URI,
            scope:                  scope,
            enable_self_signed_jwt: enable_self_signed_jwt,
            target_audience:        target_audience,
            issuer:                 client_email,
            signing_key:            OpenSSL::PKey::RSA.new(private_key),
            project_id:             project_id,
            quota_project_id:       quota_project_id,
            universe_domain:        universe_domain || "googleapis.com")
          .configure_connection(options)
      end

      # Creates a duplicate of these credentials
      # without the Signet::OAuth2::Client-specific
      # transient state (e.g. cached tokens)
      #
      # @param options [Hash] Overrides for the credentials parameters.
      #   The following keys are recognized in addition to keys in the
      #   Signet::OAuth2::Client
      #   * `:enable_self_signed_jwt` Whether the self-signed JWT should
      #     be used for the authentication
      #   * `project_id` the project id to use during the authentication
      #   * `quota_project_id` the quota project id to use
      #     during the authentication
      def duplicate options = {}
        options = deep_hash_normalize options
        super(
          {
            enable_self_signed_jwt: @enable_self_signed_jwt,
            project_id: project_id,
            quota_project_id: quota_project_id,
            logger: logger
          }.merge(options)
        )
      end

      # Handles certain escape sequences that sometimes appear in input.
      # Specifically, interprets the "\n" sequence for newline, and removes
      # enclosing quotes.
      #
      # @param str [String] The string to unescape
      # @return [String] The unescaped string
      def self.unescape str
        str = str.gsub '\n', "\n"
        str = str[1..-2] if str.start_with?('"') && str.end_with?('"')
        str
      end

      def initialize options = {}
        @project_id = options[:project_id]
        @quota_project_id = options[:quota_project_id]
        @enable_self_signed_jwt = options[:enable_self_signed_jwt] ? true : false
        super options
      end

      # Extends the base class to use a transient
      # ServiceAccountJwtHeaderCredentials for certain cases.
      def apply! a_hash, opts = {}
        if enable_self_signed_jwt?
          apply_self_signed_jwt! a_hash
        else
          super
        end
      end

      # Modifies this logic so it also requires self-signed-jwt to be disabled
      def needs_access_token?
        super && !enable_self_signed_jwt?
      end

      # Destructively updates these credentials
      #
      # This method is called by `Signet::OAuth2::Client`'s constructor
      #
      # @param options [Hash] Overrides for the credentials parameters.
      #   The following keys are recognized in addition to keys in the
      #   Signet::OAuth2::Client
      #   * `:enable_self_signed_jwt` Whether the self-signed JWT should
      #     be used for the authentication
      #   * `project_id` the project id to use during the authentication
      #   * `quota_project_id` the quota project id to use
      #     during the authentication
      # @return [Google::Auth::ServiceAccountCredentials]
      def update! options = {}
        # Normalize all keys to symbols to allow indifferent access.
        options = deep_hash_normalize options

        @enable_self_signed_jwt = options[:enable_self_signed_jwt] ? true : false
        @project_id = options[:project_id] if options.key? :project_id
        @quota_project_id = options[:quota_project_id] if options.key? :quota_project_id

        super(options)

        self
      end

      # Returns the client email as the principal for service account credentials
      # @private
      # @return [String] the email address of the service account
      def principal
        @issuer
      end

      private

      def apply_self_signed_jwt! a_hash
        # Use the ServiceAccountJwtHeaderCredentials using the same cred values
        alt = ServiceAccountJwtHeaderCredentials.new(
          private_key:      @signing_key.to_s,
          issuer:           @issuer,
          project_id:       @project_id,
          quota_project_id: @quota_project_id,
          universe_domain:  universe_domain,
          scope:            scope,
          logger:           logger
        )
        alt.apply! a_hash
      end

      # @private
      # Loads service account credential details from environment variables.
      #
      # @return [Array<String, String, String, nil, nil>] An array containing private_key,
      #   client_email, project_id, quota_project_id, and universe_domain.
      def self.creds_from_env
        private_key = unescape ENV[CredentialsLoader::PRIVATE_KEY_VAR]
        client_email = ENV[CredentialsLoader::CLIENT_EMAIL_VAR]
        project_id = ENV[CredentialsLoader::PROJECT_ID_VAR]
        [private_key, client_email, project_id, nil, nil]
      end

      private_class_method :creds_from_env
    end
  end
end
