# Copyright 2023 Google, Inc.
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
# limitations under the License.require "time"

require "googleauth/base_client"
require "googleauth/errors"
require "googleauth/helpers/connection"
require "googleauth/oauth2/sts_client"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    module ExternalAccount
      # Authenticates requests using External Account credentials, such
      # as those provided by the AWS provider or OIDC provider like Azure, etc.
      module BaseCredentials
        # Contains all methods needed for all external account credentials.
        # Other credentials should call `base_setup` during initialization
        # And should define the :retrieve_subject_token! method

        # External account JSON type identifier.
        EXTERNAL_ACCOUNT_JSON_TYPE = "external_account".freeze
        # The token exchange grant_type used for exchanging credentials.
        STS_GRANT_TYPE = "urn:ietf:params:oauth:grant-type:token-exchange".freeze
        # The token exchange requested_token_type. This is always an access_token.
        STS_REQUESTED_TOKEN_TYPE = "urn:ietf:params:oauth:token-type:access_token".freeze
        # Default IAM_SCOPE
        IAM_SCOPE = ["https://www.googleapis.com/auth/iam".freeze].freeze

        include Google::Auth::BaseClient
        include Helpers::Connection

        attr_reader :expires_at
        attr_accessor :access_token
        attr_accessor :universe_domain

        def expires_within? seconds
          # This method is needed for BaseClient
          @expires_at && @expires_at - Time.now.utc < seconds
        end

        def expires_at= new_expires_at
          @expires_at = normalize_timestamp new_expires_at
        end

        def fetch_access_token! _options = {}
          # This method is needed for BaseClient
          response = exchange_token

          if @service_account_impersonation_url
            impersonated_response = get_impersonated_access_token response["access_token"]
            self.expires_at = impersonated_response["expireTime"]
            self.access_token = impersonated_response["accessToken"]
          else
            # Extract the expiration time in seconds from the response and calculate the actual expiration time
            # and then save that to the expiry variable.
            self.expires_at = Time.now.utc + response["expires_in"].to_i
            self.access_token = response["access_token"]
          end

          notify_refresh_listeners
        end

        # Retrieves the subject token using the credential_source object.
        # @return [string]
        #     The retrieved subject token.
        #
        def retrieve_subject_token!
          raise NoMethodError, "retrieve_subject_token! not implemented"
        end

        # Returns whether the credentials represent a workforce pool (True) or
        # workload (False) based on the credentials' audience.
        #
        # @return [bool]
        #     true if the credentials represent a workforce pool.
        #     false if they represent a workload.
        def is_workforce_pool?
          %r{/iam\.googleapis\.com/locations/[^/]+/workforcePools/}.match?(@audience || "")
        end

        # For external account credentials, the principal is
        # represented by the audience, such as a workforce pool
        # @private
        # @return [String] the GCP principal, e.g. a workforce pool
        def principal
          @audience
        end

        private

        def token_type
          # This method is needed for BaseClient
          :access_token
        end

        # A common method for Other credentials to call during initialization
        # @raise [Google::Auth::InitializationError] If workforce_pool_user_project is incorrectly set
        def base_setup options
          self.default_connection = options[:connection]

          @audience = options[:audience]
          @scope = options[:scope] || IAM_SCOPE
          @subject_token_type = options[:subject_token_type]
          @token_url = options[:token_url]
          @token_info_url = options[:token_info_url]
          @service_account_impersonation_url = options[:service_account_impersonation_url]
          @service_account_impersonation_options = options[:service_account_impersonation_options] || {}
          @client_id = options[:client_id]
          @client_secret = options[:client_secret]
          @quota_project_id = options[:quota_project_id]
          @project_id = nil
          @workforce_pool_user_project = options[:workforce_pool_user_project]
          @universe_domain = options[:universe_domain] || "googleapis.com"

          @expires_at = nil
          @access_token = nil

          @sts_client = Google::Auth::OAuth2::STSClient.new(
            token_exchange_endpoint: @token_url,
            connection: default_connection
          )
          return unless @workforce_pool_user_project && !is_workforce_pool?
          raise InitializationError, "workforce_pool_user_project should not be set for non-workforce pool credentials."
        end

        # Exchange tokens at STS endpoint
        # @raise [Google::Auth::AuthorizationError] If the token exchange request fails
        def exchange_token
          additional_options = nil
          if @client_id.nil? && @workforce_pool_user_project
            additional_options = { userProject: @workforce_pool_user_project }
          end
          token_request = {
            audience: @audience,
            grant_type: STS_GRANT_TYPE,
            subject_token: retrieve_subject_token!,
            subject_token_type: @subject_token_type,
            scopes: @service_account_impersonation_url ? IAM_SCOPE : @scope,
            requested_token_type: STS_REQUESTED_TOKEN_TYPE,
            additional_options: additional_options
          }
          log_token_request token_request
          @sts_client.exchange_token token_request
        rescue Google::Auth::AuthorizationError => e
          raise Google::Auth::AuthorizationError.with_details(
            e.message,
            credential_type_name: self.class.name,
            principal: principal
          )
        end

        def log_token_request token_request
          logger&.info do
            Google::Logging::Message.from(
              message: "Requesting access token from #{token_request[:grant_type]}",
              "credentialsId" => object_id
            )
          end
          logger&.debug do
            digest = Digest::SHA256.hexdigest token_request[:subject_token].to_s
            loggable_request = token_request.merge subject_token: "(sha256:#{digest})"
            Google::Logging::Message.from(
              message: "Request data",
              "request" => loggable_request,
              "credentialsId" => object_id
            )
          end
        end

        # Exchanges a token for an impersonated service account access token
        #
        # @param [String] token The token to exchange
        # @param [Hash] _options Additional options (not used)
        # @return [Hash] The response containing the impersonated access token
        # @raise [Google::Auth::CredentialsError] If the impersonation request fails
        def get_impersonated_access_token token, _options = {}
          log_impersonated_token_request token
          response = connection.post @service_account_impersonation_url do |req|
            req.headers["Authorization"] = "Bearer #{token}"
            req.headers["Content-Type"] = "application/json"
            req.body = MultiJson.dump({ scope: @scope })
          end

          if response.status != 200
            raise CredentialsError.with_details(
              "Service account impersonation failed with status #{response.status}",
              credential_type_name: self.class.name,
              principal: principal
            )
          end

          MultiJson.load response.body
        end

        def log_impersonated_token_request original_token
          logger&.info do
            digest = Digest::SHA256.hexdigest original_token
            Google::Logging::Message.from(
              message: "Requesting impersonated access token with original token (sha256:#{digest})",
              "credentialsId" => object_id
            )
          end
        end
      end
    end
  end
end
