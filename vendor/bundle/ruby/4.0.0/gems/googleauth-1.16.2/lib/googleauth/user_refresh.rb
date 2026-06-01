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

require "googleauth/credentials_loader"
require "googleauth/errors"
require "googleauth/scope_util"
require "googleauth/signet"
require "multi_json"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    # Authenticates requests using User Refresh credentials.
    #
    # This class allows authorizing requests from user refresh tokens.
    #
    # This the end of the result of a 3LO flow.  E.g, the end result of
    # 'gcloud auth login' saves a file with these contents in well known
    # location
    #
    # cf [Application Default Credentials](https://cloud.google.com/docs/authentication/production)
    class UserRefreshCredentials < Signet::OAuth2::Client
      TOKEN_CRED_URI = "https://oauth2.googleapis.com/token".freeze
      AUTHORIZATION_URI = "https://accounts.google.com/o/oauth2/auth".freeze
      REVOKE_TOKEN_URI = "https://oauth2.googleapis.com/revoke".freeze
      extend CredentialsLoader
      attr_reader :project_id
      attr_reader :quota_project_id

      # @private
      # @type [::String] The type name for this credential.
      CREDENTIAL_TYPE_NAME = "authorized_user".freeze

      # Create a UserRefreshCredentials.
      #
      # @param json_key_io [IO] An IO object containing the JSON key
      # @param scope [string|array|nil] the scope(s) to access
      def self.make_creds options = {} # rubocop:disable Metrics/MethodLength
        json_key_io, scope = options.values_at :json_key_io, :scope
        user_creds = if json_key_io
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
                       {
                         "client_id"     => ENV[CredentialsLoader::CLIENT_ID_VAR],
                         "client_secret" => ENV[CredentialsLoader::CLIENT_SECRET_VAR],
                         "refresh_token" => ENV[CredentialsLoader::REFRESH_TOKEN_VAR],
                         "project_id"    => ENV[CredentialsLoader::PROJECT_ID_VAR],
                         "quota_project_id" => nil,
                         "universe_domain" => nil
                       }
                     end
        new(token_credential_uri: TOKEN_CRED_URI,
            client_id:            user_creds["client_id"],
            client_secret:        user_creds["client_secret"],
            refresh_token:        user_creds["refresh_token"],
            project_id:           user_creds["project_id"],
            quota_project_id:     user_creds["quota_project_id"],
            scope:                scope,
            universe_domain:      user_creds["universe_domain"] || "googleapis.com")
          .configure_connection(options)
      end

      # Reads a JSON key from an IO object and extracts required fields.
      #
      # @param [IO] json_key_io An IO object containing the JSON key
      # @return [Hash] The parsed JSON key
      # @raise [Google::Auth::InitializationError] If the JSON is missing required fields
      def self.read_json_key json_key_io
        json_key = MultiJson.load json_key_io.read
        wanted = ["client_id", "client_secret", "refresh_token"]
        wanted.each do |key|
          raise InitializationError, "the json is missing the #{key} field" unless json_key.key? key
        end
        json_key
      end

      def initialize options = {}
        options ||= {}
        options[:token_credential_uri] ||= TOKEN_CRED_URI
        options[:authorization_uri] ||= AUTHORIZATION_URI
        @project_id = options[:project_id]
        @project_id ||= CredentialsLoader.load_gcloud_project_id
        @quota_project_id = options[:quota_project_id]
        super options
      end

      # Creates a duplicate of these credentials
      # without the Signet::OAuth2::Client-specific
      # transient state (e.g. cached tokens)
      #
      # @param options [Hash] Overrides for the credentials parameters.
      #   The following keys are recognized in addition to keys in the
      #   Signet::OAuth2::Client
      #   * `project_id` the project id to use during the authentication
      #   * `quota_project_id` the quota project id to use
      #     during the authentication
      def duplicate options = {}
        options = deep_hash_normalize options
        super(
          {
            project_id: @project_id,
            quota_project_id: @quota_project_id
          }.merge(options)
        )
      end

      # Revokes the credential
      #
      # @param [Hash] options Options for revoking the credential
      # @option options [Faraday::Connection] :connection The connection to use
      # @raise [Google::Auth::AuthorizationError] If the revocation request fails
      def revoke! options = {}
        c = options[:connection] || Faraday.default_connection

        retry_with_error do
          resp = c.post(REVOKE_TOKEN_URI, token: refresh_token || access_token)
          case resp.status
          when 200
            self.access_token = nil
            self.refresh_token = nil
            self.expires_at = 0
          else
            raise AuthorizationError.with_details(
              "Unexpected error code #{resp.status}",
              credential_type_name: self.class.name,
              principal: principal
            )
          end

          resp.body
        end
      end

      # Verifies that a credential grants the requested scope
      #
      # @param [Array<String>, String] required_scope
      #  Scope to verify
      # @return [Boolean]
      #  True if scope is granted
      def includes_scope? required_scope
        missing_scope = Google::Auth::ScopeUtil.normalize(required_scope) -
                        Google::Auth::ScopeUtil.normalize(scope)
        missing_scope.empty?
      end

      # Destructively updates these credentials
      #
      # This method is called by `Signet::OAuth2::Client`'s constructor
      #
      # @param options [Hash] Overrides for the credentials parameters.
      #   The following keys are recognized in addition to keys in the
      #   Signet::OAuth2::Client
      #   * `project_id` the project id to use during the authentication
      #   * `quota_project_id` the quota project id to use
      #     during the authentication
      # @return [Google::Auth::UserRefreshCredentials]
      def update! options = {}
        # Normalize all keys to symbols to allow indifferent access.
        options = deep_hash_normalize options

        @project_id = options[:project_id] if options.key? :project_id
        @quota_project_id = options[:quota_project_id] if options.key? :quota_project_id

        super(options)

        self
      end

      # Returns the client ID as the principal for user refresh credentials
      # @private
      # @return [String, Symbol] the client ID or :user_refresh if not available
      def principal
        @client_id || :user_refresh
      end
    end
  end
end
