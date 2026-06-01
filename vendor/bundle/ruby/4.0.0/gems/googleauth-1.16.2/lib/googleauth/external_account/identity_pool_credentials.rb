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
# limitations under the License.

require "time"
require "googleauth/errors"
require "googleauth/external_account/base_credentials"
require "googleauth/external_account/external_account_utils"

module Google
  # Module Auth provides classes that provide Google-specific authorization used to access Google APIs.
  module Auth
    module ExternalAccount
      # This module handles the retrieval of credentials from Google Cloud by utilizing the any 3PI
      # provider then exchanging the credentials for a short-lived Google Cloud access token.
      class IdentityPoolCredentials
        include Google::Auth::ExternalAccount::BaseCredentials
        include Google::Auth::ExternalAccount::ExternalAccountUtils
        extend CredentialsLoader

        # Will always be nil, but method still gets used.
        attr_reader :client_id

        # Initialize from options map.
        #
        # @param [Hash] options Configuration options
        # @option options [String] :audience The audience for the token
        # @option options [Hash{Symbol => Object}] :credential_source A hash containing either source file or url.
        #     credential_source_format is either text or json to define how to parse the credential response.
        # @raise [Google::Auth::InitializationError] If credential_source format is invalid, field_name is missing,
        #     contains ambiguous sources, or is missing required fields
        #
        def initialize options = {}
          base_setup options

          @audience = options[:audience]
          @credential_source = options[:credential_source] || {}
          @credential_source_file = @credential_source[:file]
          @credential_source_url = @credential_source[:url]
          @credential_source_headers = @credential_source[:headers] || {}
          @credential_source_format = @credential_source[:format] || {}
          @credential_source_format_type = @credential_source_format[:type] || "text"
          validate_credential_source
        end

        # Implementation of BaseCredentials retrieve_subject_token!
        #
        # @return [String] The subject token
        # @raise [Google::Auth::CredentialsError] If the token can't be parsed from JSON or is missing
        def retrieve_subject_token!
          content, resource_name = token_data
          if @credential_source_format_type == "text"
            token = content
          else
            begin
              response_data = MultiJson.load content, symbolize_keys: true
              token = response_data[@credential_source_field_name.to_sym]
            rescue StandardError
              raise CredentialsError, "Unable to parse subject_token from JSON resource #{resource_name} " \
                                      "using key #{@credential_source_field_name}"
            end
          end
          raise CredentialsError, "Missing subject_token in the credential_source file/response." unless token
          token
        end

        private

        # Validates input
        #
        # @raise [Google::Auth::InitializationError] If credential_source format is invalid, field_name is missing,
        #     contains ambiguous sources, or is missing required fields
        def validate_credential_source
          # `environment_id` is only supported in AWS or dedicated future external account credentials.
          unless @credential_source[:environment_id].nil?
            raise InitializationError, "Invalid Identity Pool credential_source field 'environment_id'"
          end
          unless ["json", "text"].include? @credential_source_format_type
            raise InitializationError, "Invalid credential_source format #{@credential_source_format_type}"
          end
          # for JSON types, get the required subject_token field name.
          @credential_source_field_name = @credential_source_format[:subject_token_field_name]
          if @credential_source_format_type == "json" && @credential_source_field_name.nil?
            raise InitializationError, "Missing subject_token_field_name for JSON credential_source format"
          end
          # check file or url must be fulfilled and mutually exclusiveness.
          if @credential_source_file && @credential_source_url
            raise InitializationError, "Ambiguous credential_source. 'file' is mutually exclusive with 'url'."
          end
          return unless (@credential_source_file || @credential_source_url).nil?
          raise InitializationError, "Missing credential_source. A 'file' or 'url' must be provided."
        end

        def token_data
          @credential_source_file.nil? ? url_data : file_data
        end

        # Reads data from a file source
        #
        # @return [Array(String, String)] The file content and file path
        # @raise [Google::Auth::CredentialsError] If the source file doesn't exist
        def file_data
          unless File.exist? @credential_source_file
            raise CredentialsError,
                  "File #{@credential_source_file} was not found."
          end
          content = File.read @credential_source_file, encoding: "utf-8"
          [content, @credential_source_file]
        end

        # Fetches data from a URL source
        #
        # @return [Array(String, String)] The response body and URL
        # @raise [Google::Auth::CredentialsError] If there's an error retrieving data from the URL
        #   or if the response is not successful
        def url_data
          begin
            response = connection.get @credential_source_url do |req|
              req.headers.merge! @credential_source_headers
            end
          rescue Faraday::Error => e
            raise CredentialsError, "Error retrieving from credential url: #{e}"
          end
          unless response.success?
            raise CredentialsError,
                  "Unable to retrieve Identity Pool subject token #{response.body}"
          end
          [response.body, @credential_source_url]
        end
      end
    end
  end
end
