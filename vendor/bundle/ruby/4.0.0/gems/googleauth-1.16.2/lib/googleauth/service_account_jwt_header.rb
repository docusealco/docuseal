# Copyright 2025 Google, Inc.
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

require "google/logging/message"
require "googleauth/credentials_loader"
require "googleauth/json_key_reader"
require "jwt"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    # Authenticates requests using Google's Service Account credentials via
    # JWT Header.
    #
    # This class allows authorizing requests for service accounts directly
    # from credentials from a json key file downloaded from the developer
    # console (via 'Generate new Json Key').  It is not part of any OAuth2
    # flow, rather it creates a JWT and sends that as a credential.
    #
    # cf [Application Default Credentials](https://cloud.google.com/docs/authentication/production)
    class ServiceAccountJwtHeaderCredentials
      JWT_AUD_URI_KEY = :jwt_aud_uri
      AUTH_METADATA_KEY = Google::Auth::BaseClient::AUTH_METADATA_KEY
      TOKEN_CRED_URI = "https://www.googleapis.com/oauth2/v4/token".freeze
      SIGNING_ALGORITHM = "RS256".freeze
      EXPIRY = 60

      extend CredentialsLoader
      extend JsonKeyReader

      attr_reader :project_id
      attr_reader :quota_project_id
      attr_accessor :universe_domain
      attr_accessor :logger

      # Create a ServiceAccountJwtHeaderCredentials.
      #
      # @param json_key_io [IO] An IO object containing the JSON key
      # @param scope [string|array|nil] the scope(s) to access
      def self.make_creds options = {}
        json_key_io, scope = options.values_at :json_key_io, :scope
        new json_key_io: json_key_io, scope: scope
      end

      # Initializes a ServiceAccountJwtHeaderCredentials.
      #
      # @param json_key_io [IO] An IO object containing the JSON key
      def initialize options = {}
        json_key_io = options[:json_key_io]
        if json_key_io
          @private_key, @issuer, @project_id, @quota_project_id, @universe_domain =
            self.class.read_json_key json_key_io
        else
          @private_key = options.key?(:private_key) ? options[:private_key] : ENV[CredentialsLoader::PRIVATE_KEY_VAR]
          @issuer = options.key?(:issuer) ? options[:issuer] : ENV[CredentialsLoader::CLIENT_EMAIL_VAR]
          @project_id = options.key?(:project_id) ? options[:project_id] : ENV[CredentialsLoader::PROJECT_ID_VAR]
          @quota_project_id = options[:quota_project_id] if options.key? :quota_project_id
          @universe_domain = options[:universe_domain] if options.key? :universe_domain
        end
        @universe_domain ||= "googleapis.com"
        @project_id ||= CredentialsLoader.load_gcloud_project_id
        @signing_key = OpenSSL::PKey::RSA.new @private_key
        @scope = options[:scope] if options.key? :scope
        @logger = options[:logger] if options.key? :logger
      end

      # Creates a duplicate of these credentials
      #
      # @param options [Hash] Overrides for the credentials parameters.
      #   The following keys are recognized
      #   * `private key` the private key in string form
      #   * `issuer` the SA issuer
      #   * `scope` the scope(s) to access
      #   * `project_id` the project id to use during the authentication
      #   * `quota_project_id` the quota project id to use
      #   * `universe_domain` the universe domain of the credentials
      def duplicate options = {}
        options = deep_hash_normalize options

        options = {
          private_key: @private_key,
          issuer: @issuer,
          scope: @scope,
          project_id: project_id,
          quota_project_id: quota_project_id,
          universe_domain: universe_domain,
          logger: logger
        }.merge(options)

        self.class.new options
      end

      # Construct a jwt token if the JWT_AUD_URI key is present in the input
      # hash.
      #
      # The jwt token is used as the value of a 'Bearer '.
      def apply! a_hash, opts = {}
        jwt_aud_uri = a_hash.delete JWT_AUD_URI_KEY
        return a_hash if jwt_aud_uri.nil? && @scope.nil?
        jwt_token = new_jwt_token jwt_aud_uri, opts
        a_hash[AUTH_METADATA_KEY] = "Bearer #{jwt_token}"
        logger&.debug do
          hash = Digest::SHA256.hexdigest jwt_token
          Google::Logging::Message.from message: "Sending JWT auth token. (sha256:#{hash})"
        end
        a_hash
      end

      # Returns a clone of a_hash updated with the authorization header
      def apply a_hash, opts = {}
        a_copy = a_hash.clone
        apply! a_copy, opts
        a_copy
      end

      # Returns a reference to the #apply method, suitable for passing as
      # a closure
      def updater_proc
        proc { |a_hash, opts = {}| apply a_hash, opts }
      end

      # Creates a jwt uri token.
      def new_jwt_token jwt_aud_uri = nil, options = {}
        now = Time.new
        skew = options[:skew] || 60
        assertion = {
          "iss" => @issuer,
          "sub" => @issuer,
          "exp" => (now + EXPIRY).to_i,
          "iat" => (now - skew).to_i
        }

        jwt_aud_uri = nil if @scope

        assertion["scope"] = Array(@scope).join " " if @scope
        assertion["aud"] = jwt_aud_uri if jwt_aud_uri

        logger&.debug do
          Google::Logging::Message.from message: "JWT assertion: #{assertion}"
        end

        JWT.encode assertion, @signing_key, SIGNING_ALGORITHM
      end

      # Duck-types the corresponding method from BaseClient
      def needs_access_token?
        false
      end

      # Returns the client email as the principal for service account JWT header credentials
      # @private
      # @return [String] the email address of the service account
      def principal
        @issuer
      end

      private

      def deep_hash_normalize old_hash
        sym_hash = {}
        old_hash&.each { |k, v| sym_hash[k.to_sym] = recursive_hash_normalize_keys v }
        sym_hash
      end

      # Convert all keys in this hash (nested) to symbols for uniform retrieval
      def recursive_hash_normalize_keys val
        if val.is_a? Hash
          deep_hash_normalize val
        else
          val
        end
      end
    end
  end
end
