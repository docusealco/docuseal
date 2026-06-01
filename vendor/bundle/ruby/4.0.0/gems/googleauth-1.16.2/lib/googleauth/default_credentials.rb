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

require "multi_json"
require "stringio"

require "googleauth/credentials_loader"
require "googleauth/errors"
require "googleauth/external_account"
require "googleauth/service_account"
require "googleauth/service_account_jwt_header"
require "googleauth/user_refresh"
require "googleauth/impersonated_service_account"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    # DefaultCredentials is used to preload the credentials file, to determine
    # which type of credentials should be loaded.
    class DefaultCredentials
      extend CredentialsLoader

      ##
      # Override CredentialsLoader#make_creds to use the class determined by
      # loading the json.
      #
      # **Important:** If you accept a credential configuration (credential
      # JSON/File/Stream) from an external source for authentication to Google
      # Cloud, you must validate it before providing it to any Google API or
      # library. Providing an unvalidated credential configuration to Google
      # APIs can compromise the security of your systems and data. For more
      # information, refer to [Validate credential configurations from external
      # sources](https://cloud.google.com/docs/authentication/external/externally-sourced-credentials).
      #
      # @deprecated This method is deprecated and will be removed in a future version.
      #   Please use the `make_creds` method on the specific credential class you intend to load,
      #   e.g., `Google::Auth::ServiceAccountCredentials.make_creds`.
      #
      #   This method does not validate the credential configuration. The security
      #   risk occurs when a credential configuration is accepted from a source that
      #   is not under your control and used without validation on your side.
      #
      #   If you know that you will be loading credential configurations of a
      #   specific type, it is recommended to use a credential-type-specific
      #   `make_creds` method.
      #   This will ensure that an unexpected credential type with potential for
      #   malicious intent is not loaded unintentionally. You might still have to do
      #   validation for certain credential types. Please follow the recommendation
      #   for that method. For example, if you want to load only service accounts,
      #   you can use:
      #   ```
      #   creds = Google::Auth::ServiceAccountCredentials.make_creds
      #   ```
      #   @see Google::Auth::ServiceAccountCredentials.make_creds
      #
      #   If you are loading your credential configuration from an untrusted source and have
      #   not mitigated the risks (e.g. by validating the configuration yourself), make
      #   these changes as soon as possible to prevent security risks to your environment.
      #
      #   Regardless of the method used, it is always your responsibility to validate
      #   configurations received from external sources.
      #
      #   See https://cloud.google.com/docs/authentication/external/externally-sourced-credentials for more details.
      #
      # @param options [Hash] Options for creating the credentials
      # @return [Google::Auth::Credentials] The credentials instance
      # @raise [Google::Auth::InitializationError] If the credentials cannot be determined
      def self.make_creds options = {}
        json_key_io = options[:json_key_io]
        json_key, clz = determine_creds_class json_key_io
        if json_key
          io = StringIO.new MultiJson.dump(json_key)
          clz.make_creds options.merge(json_key_io: io)
        else
          clz.make_creds options
        end
      end

      # Reads the input json and determines which creds class to use.
      #
      # @param json_key_io [IO, nil] An optional IO object containing the JSON key.
      #   If nil, the credential type is determined from environment variables.
      # @return [Array(Hash, Class)] The JSON key (or nil if from environment) and the credential class to use
      # @raise [Google::Auth::InitializationError] If the JSON is missing the type field or has an unsupported type,
      #   or if the environment variable is undefined or unsupported.
      def self.determine_creds_class json_key_io = nil
        if json_key_io
          json_key = MultiJson.load json_key_io.read
          key = "type"
          raise InitializationError, "the json is missing the '#{key}' field" unless json_key.key? key
          type = json_key[key]
        else
          env_var = CredentialsLoader::ACCOUNT_TYPE_VAR
          type = ENV[env_var]
          raise InitializationError, "#{env_var} is undefined in env" unless type
          json_key = nil
        end

        clz = case type
              when ServiceAccountCredentials::CREDENTIAL_TYPE_NAME
                ServiceAccountCredentials
              when UserRefreshCredentials::CREDENTIAL_TYPE_NAME
                UserRefreshCredentials
              when ExternalAccount::Credentials::CREDENTIAL_TYPE_NAME
                ExternalAccount::Credentials
              when ImpersonatedServiceAccountCredentials::CREDENTIAL_TYPE_NAME
                ImpersonatedServiceAccountCredentials
              else
                raise InitializationError, "credentials type '#{type}' is not supported"
              end
        [json_key, clz]
      end
    end
  end
end
