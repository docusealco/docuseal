# Copyright 2022 Google, Inc.
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

require "time"
require "uri"
require "googleauth/credentials_loader"
require "googleauth/errors"
require "googleauth/external_account/aws_credentials"
require "googleauth/external_account/identity_pool_credentials"
require "googleauth/external_account/pluggable_credentials"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    # Authenticates requests using External Account credentials, such
    # as those provided by the AWS provider.
    module ExternalAccount
      # Provides an entrypoint for all Exernal Account credential classes.
      class Credentials
        # The subject token type used for AWS external_account credentials.
        AWS_SUBJECT_TOKEN_TYPE = "urn:ietf:params:aws:token-type:aws4_request".freeze
        MISSING_CREDENTIAL_SOURCE = "missing credential source for external account".freeze
        INVALID_EXTERNAL_ACCOUNT_TYPE = "credential source is not supported external account type".freeze

        # @private
        # @type [::String] The type name for this credential.
        CREDENTIAL_TYPE_NAME = "external_account".freeze

        # Create a ExternalAccount::Credentials
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
        # @param options [Hash] Options for creating credentials
        # @option options [IO] :json_key_io (required) An IO object containing the JSON key
        # @option options [String,Array,nil] :scope The scope(s) to access
        # @return [Google::Auth::ExternalAccount::AwsCredentials,
        #   Google::Auth::ExternalAccount::IdentityPoolCredentials,
        #   Google::Auth::ExternalAccount::PluggableAuthCredentials]
        #   The appropriate external account credentials based on the credential source
        # @raise [Google::Auth::InitializationError] If the json file is missing, lacks required fields,
        #   or does not contain a supported credential source
        def self.make_creds options = {}
          json_key_io, scope = options.values_at :json_key_io, :scope

          raise InitializationError, "A json file is required for external account credentials." unless json_key_io
          json_key = MultiJson.load json_key_io.read, symbolize_keys: true
          if json_key.key? :type
            json_key_io.rewind
          else # Defaults to class credential 'type' if missing.
            json_key[:type] = CREDENTIAL_TYPE_NAME
            json_key_io = StringIO.new MultiJson.dump(json_key)
          end
          CredentialsLoader.load_and_verify_json_key_type json_key_io, CREDENTIAL_TYPE_NAME
          user_creds = read_json_key json_key_io

          # AWS credentials is determined by aws subject token type
          return make_aws_credentials user_creds, scope if user_creds[:subject_token_type] == AWS_SUBJECT_TOKEN_TYPE

          raise InitializationError, MISSING_CREDENTIAL_SOURCE if user_creds[:credential_source].nil?
          user_creds[:scope] = scope
          make_external_account_credentials user_creds
        end

        # Reads the required fields from the JSON.
        #
        # @param json_key_io [IO] An IO object containing the JSON key
        # @return [Hash] The parsed JSON key
        # @raise [Google::Auth::InitializationError] If the JSON is missing required fields
        def self.read_json_key json_key_io
          json_key = MultiJson.load json_key_io.read, symbolize_keys: true
          wanted = [
            :audience, :subject_token_type, :token_url, :credential_source
          ]
          wanted.each do |key|
            raise InitializationError, "the json is missing the #{key} field" unless json_key.key? key
          end
          json_key
        end

        class << self
          private

          # Creates AWS credentials from the provided user credentials
          #
          # @param user_creds [Hash] The user credentials containing AWS credential source information
          # @param scope [String,Array,nil] The scope(s) to access
          # @return [Google::Auth::ExternalAccount::AwsCredentials] The AWS credentials
          def make_aws_credentials user_creds, scope
            Google::Auth::ExternalAccount::AwsCredentials.new(
              audience: user_creds[:audience],
              scope: scope,
              subject_token_type: user_creds[:subject_token_type],
              token_url: user_creds[:token_url],
              credential_source: user_creds[:credential_source],
              service_account_impersonation_url: user_creds[:service_account_impersonation_url],
              universe_domain: user_creds[:universe_domain]
            )
          end

          # Creates the appropriate external account credentials based on the credential source type
          #
          # @param user_creds [Hash] The user credentials containing credential source information
          # @return [Google::Auth::ExternalAccount::IdentityPoolCredentials,
          #   Google::Auth::ExternalAccount::PluggableAuthCredentials]
          #   The appropriate external account credentials
          # @raise [Google::Auth::InitializationError] If the credential source is not a supported type
          def make_external_account_credentials user_creds
            unless user_creds[:credential_source][:file].nil? && user_creds[:credential_source][:url].nil?
              return Google::Auth::ExternalAccount::IdentityPoolCredentials.new user_creds
            end
            unless user_creds[:credential_source][:executable].nil?
              return Google::Auth::ExternalAccount::PluggableAuthCredentials.new user_creds
            end
            raise InitializationError, INVALID_EXTERNAL_ACCOUNT_TYPE
          end
        end
      end
    end
  end
end
