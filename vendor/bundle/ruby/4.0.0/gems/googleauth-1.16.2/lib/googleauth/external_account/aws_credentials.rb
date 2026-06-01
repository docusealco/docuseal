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
    # Authenticates requests using External Account credentials, such as those provided by the AWS provider.
    module ExternalAccount
      # This module handles the retrieval of credentials from Google Cloud by utilizing the AWS EC2 metadata service and
      # then exchanging the credentials for a short-lived Google Cloud access token.
      class AwsCredentials
        # Constant for imdsv2 session token expiration in seconds
        IMDSV2_TOKEN_EXPIRATION_IN_SECONDS = 300

        include Google::Auth::ExternalAccount::BaseCredentials
        include Google::Auth::ExternalAccount::ExternalAccountUtils
        extend CredentialsLoader

        # Will always be nil, but method still gets used.
        attr_reader :client_id

        def initialize options = {}
          base_setup options

          @audience = options[:audience]
          @credential_source = options[:credential_source] || {}
          @environment_id = @credential_source[:environment_id]
          @region_url = @credential_source[:region_url]
          @credential_verification_url = @credential_source[:url]
          @regional_cred_verification_url = @credential_source[:regional_cred_verification_url]
          @imdsv2_session_token_url = @credential_source[:imdsv2_session_token_url]

          # These will be lazily loaded when needed, or will raise an error if not provided
          @region = nil
          @request_signer = nil
          @imdsv2_session_token = nil
          @imdsv2_session_token_expiry = nil
        end

        # Retrieves the subject token using the credential_source object.
        # The subject token is a serialized [AWS GetCallerIdentity signed request](
        #   https://cloud.google.com/iam/docs/access-resources-aws#exchange-token).
        #
        # The logic is summarized as:
        #
        # Retrieve the AWS region from the AWS_REGION or AWS_DEFAULT_REGION environment variable or from the AWS
        # metadata server availability-zone if not found in the environment variable.
        #
        # Check AWS credentials in environment variables. If not found, retrieve from the AWS metadata server
        # security-credentials endpoint.
        #
        # When retrieving AWS credentials from the metadata server security-credentials endpoint, the AWS role needs to
        # be determined by # calling the security-credentials endpoint without any argument.
        # Then the credentials can be retrieved via: security-credentials/role_name
        #
        # Generate the signed request to AWS STS GetCallerIdentity action.
        #
        # Inject x-goog-cloud-target-resource into header and serialize the signed request.
        # This will be the subject-token to pass to GCP STS.
        #
        # @return [string] The retrieved subject token.
        #
        def retrieve_subject_token!
          if @request_signer.nil?
            @region = region
            @request_signer = AwsRequestSigner.new @region
          end

          request = {
            method: "POST",
            url: @regional_cred_verification_url.sub("{region}", @region)
          }

          request_options = @request_signer.generate_signed_request fetch_security_credentials, request

          request_headers = request_options[:headers]
          request_headers["x-goog-cloud-target-resource"] = @audience

          aws_signed_request = {
            headers: [],
            method: request_options[:method],
            url: request_options[:url]
          }

          aws_signed_request[:headers] = request_headers.keys.sort.map do |key|
            { key: key, value: request_headers[key] }
          end

          uri_escape aws_signed_request.to_json
        end

        private

        # Retrieves an IMDSv2 session token or returns a cached token if valid
        #
        # @return [String] The IMDSv2 session token
        # @raise [Google::Auth::CredentialsError] If the token URL is missing or there's an error retrieving the token
        def imdsv2_session_token
          return @imdsv2_session_token unless imdsv2_session_token_invalid?
          if @imdsv2_session_token_url.nil?
            raise CredentialsError.with_details(
              "IMDSV2 token url must be provided",
              credential_type_name: self.class.name,
              principal: principal
            )
          end
          begin
            response = connection.put @imdsv2_session_token_url do |req|
              req.headers["x-aws-ec2-metadata-token-ttl-seconds"] = IMDSV2_TOKEN_EXPIRATION_IN_SECONDS.to_s
            end
            raise Faraday::Error unless response.success?
          rescue Faraday::Error => e
            raise CredentialsError.with_details(
              "Fetching AWS IMDSV2 token error: #{e}",
              credential_type_name: self.class.name,
              principal: principal
            )
          end

          @imdsv2_session_token = response.body
          @imdsv2_session_token_expiry = Time.now + IMDSV2_TOKEN_EXPIRATION_IN_SECONDS
          @imdsv2_session_token
        end

        def imdsv2_session_token_invalid?
          return true if @imdsv2_session_token.nil?
          @imdsv2_session_token_expiry.nil? || @imdsv2_session_token_expiry < Time.now
        end

        # Makes a request to an AWS resource endpoint
        #
        # @param [String] url The AWS endpoint URL
        # @param [String] name Resource name for error messages
        # @param [Hash, nil] data Optional data to send in POST requests
        # @param [Hash] headers Optional request headers
        # @return [Faraday::Response] The successful response
        # @raise [Google::Auth::CredentialsError] If the request fails
        def get_aws_resource url, name, data: nil, headers: {}
          begin
            headers["x-aws-ec2-metadata-token"] = imdsv2_session_token
            response = if data
                         headers["Content-Type"] = "application/json"
                         connection.post url, data, headers
                       else
                         connection.get url, nil, headers
                       end
            raise Faraday::Error unless response.success?
            response
          rescue Faraday::Error
            raise CredentialsError.with_details(
              "Failed to retrieve AWS #{name}.",
              credential_type_name: self.class.name,
              principal: principal
            )
          end
        end

        def uri_escape string
          if string.nil?
            nil
          else
            CGI.escape(string.encode("UTF-8")).gsub("+", "%20").gsub("%7E", "~")
          end
        end

        # Retrieves the AWS security credentials required for signing AWS requests from either the AWS security
        # credentials environment variables or from the AWS metadata server.
        def fetch_security_credentials
          env_aws_access_key_id = ENV[CredentialsLoader::AWS_ACCESS_KEY_ID_VAR]
          env_aws_secret_access_key = ENV[CredentialsLoader::AWS_SECRET_ACCESS_KEY_VAR]
          # This is normally not available for permanent credentials.
          env_aws_session_token = ENV[CredentialsLoader::AWS_SESSION_TOKEN_VAR]

          if env_aws_access_key_id && env_aws_secret_access_key
            return {
              access_key_id: env_aws_access_key_id,
              secret_access_key: env_aws_secret_access_key,
              session_token: env_aws_session_token
            }
          end

          role_name = fetch_metadata_role_name
          credentials = fetch_metadata_security_credentials role_name

          {
            access_key_id: credentials["AccessKeyId"],
            secret_access_key: credentials["SecretAccessKey"],
            session_token: credentials["Token"]
          }
        end

        # Retrieves the AWS role currently attached to the current AWS workload by querying the AWS metadata server.
        # This is needed for the AWS metadata server security credentials endpoint in order to retrieve the AWS security
        # credentials needed to sign requests to AWS APIs.
        #
        # @return [String] The AWS role name
        # @raise [Google::Auth::CredentialsError] If the credential verification URL is not set or if the request fails
        def fetch_metadata_role_name
          unless @credential_verification_url
            raise CredentialsError.with_details(
              "Unable to determine the AWS metadata server security credentials endpoint",
              credential_type_name: self.class.name,
              principal: principal
            )
          end

          get_aws_resource(@credential_verification_url, "IAM Role").body
        end

        # Retrieves the AWS security credentials required for signing AWS requests from the AWS metadata server.
        def fetch_metadata_security_credentials role_name
          response = get_aws_resource "#{@credential_verification_url}/#{role_name}", "credentials"
          MultiJson.load response.body
        end

        # Reads the name of the AWS region from the environment
        #
        # @return [String] The name of the AWS region
        # @raise [Google::Auth::CredentialsError] If the region is not set in the environment
        #   and the region_url was not set in credentials source
        def region
          @region = ENV[CredentialsLoader::AWS_REGION_VAR] || ENV[CredentialsLoader::AWS_DEFAULT_REGION_VAR]

          unless @region
            unless @region_url
              raise CredentialsError.with_details(
                "region_url or region must be set for external account credentials",
                credential_type_name: self.class.name,
                principal: principal
              )
            end

            @region ||= get_aws_resource(@region_url, "region").body[0..-2]
          end

          @region
        end
      end

      # Implements an AWS request signer based on the AWS Signature Version 4 signing process.
      # https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html
      class AwsRequestSigner
        # Instantiates an AWS request signer used to compute authenticated signed requests to AWS APIs based on the AWS
        # Signature Version 4 signing process.
        #
        # @param [string] region_name
        #     The AWS region to use.
        def initialize region_name
          @region_name = region_name
        end

        # Generates an AWS signature version 4 signed request.
        #
        # Creates a signed request following the AWS Signature Version 4 process, which
        # provides secure authentication for AWS API calls. The process includes creating
        # canonical request strings, calculating signatures using the AWS credentials, and
        # building proper authorization headers.
        #
        # For detailed information on the signing process, see:
        # https://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html
        #
        # @param [Hash] aws_credentials The AWS security credentials with the following keys:
        #   @option aws_credentials [String] :access_key_id The AWS access key ID
        #   @option aws_credentials [String] :secret_access_key The AWS secret access key
        #   @option aws_credentials [String, nil] :session_token Optional AWS session token
        # @param [Hash] original_request The request to sign with the following keys:
        #   @option original_request [String] :url The AWS service URL (must be HTTPS)
        #   @option original_request [String] :method The HTTP method (GET, POST, etc.)
        #   @option original_request [Hash, nil] :headers Optional request headers
        #   @option original_request [String, nil] :data Optional request payload
        #
        # @return [Hash] The signed request with the following keys:
        #   * :url - The original URL as a string
        #   * :headers - A hash of headers with the authorization header added
        #   * :method - The HTTP method
        #   * :data - The request payload (if present)
        #
        # @raise [Google::Auth::CredentialsError] If the AWS service URL is invalid
        #
        def generate_signed_request aws_credentials, original_request
          uri = Addressable::URI.parse original_request[:url]
          unless uri.hostname && uri.scheme == "https"
            # NOTE: We use AwsCredentials name but can't access its principal since AwsRequestSigner
            # is a separate class and not a credential object with access to the audience
            raise CredentialsError.with_details(
              "Invalid AWS service URL",
              credential_type_name: AwsCredentials.name,
              principal: "aws"
            )
          end
          service_name = uri.host.split(".").first

          datetime = Time.now.utc.strftime "%Y%m%dT%H%M%SZ"
          date = datetime[0, 8]

          headers = aws_headers aws_credentials, original_request, datetime

          request_payload = original_request[:data] || ""
          content_sha256 = sha256_hexdigest request_payload

          canonical_req = canonical_request original_request[:method], uri, headers, content_sha256
          sts = string_to_sign datetime, canonical_req, service_name

          # Authorization header requires everything else to be properly setup in order to be properly
          # calculated.
          headers["Authorization"] = build_authorization_header headers, sts, aws_credentials, service_name, date

          {
            url: uri.to_s,
            headers: headers,
            method: original_request[:method],
            data: (request_payload unless request_payload.empty?)
          }.compact
        end

        private

        def aws_headers aws_credentials, original_request, datetime
          uri = Addressable::URI.parse original_request[:url]
          temp_headers = original_request[:headers] || {}
          headers = {}
          temp_headers.each_key { |k| headers[k.to_s] = temp_headers[k] }
          headers["host"] = uri.host
          headers["x-amz-date"] = datetime
          headers["x-amz-security-token"] = aws_credentials[:session_token] if aws_credentials[:session_token]
          headers
        end

        def build_authorization_header headers, sts, aws_credentials, service_name, date
          [
            "AWS4-HMAC-SHA256",
            "Credential=#{credential aws_credentials[:access_key_id], date, service_name},",
            "SignedHeaders=#{headers.keys.sort.join ';'},",
            "Signature=#{signature aws_credentials[:secret_access_key], date, sts, service_name}"
          ].join(" ")
        end

        def signature secret_access_key, date, string_to_sign, service
          k_date = hmac "AWS4#{secret_access_key}", date
          k_region = hmac k_date, @region_name
          k_service = hmac k_region, service
          k_credentials = hmac k_service, "aws4_request"

          hexhmac k_credentials, string_to_sign
        end

        def hmac key, value
          OpenSSL::HMAC.digest OpenSSL::Digest.new("sha256"), key, value
        end

        def hexhmac key, value
          OpenSSL::HMAC.hexdigest OpenSSL::Digest.new("sha256"), key, value
        end

        def credential access_key_id, date, service
          "#{access_key_id}/#{credential_scope date, service}"
        end

        def credential_scope date, service
          [
            date,
            @region_name,
            service,
            "aws4_request"
          ].join("/")
        end

        def string_to_sign datetime, canonical_request, service
          [
            "AWS4-HMAC-SHA256",
            datetime,
            credential_scope(datetime[0, 8], service),
            sha256_hexdigest(canonical_request)
          ].join("\n")
        end

        def host uri
          # Handles known and unknown URI schemes; default_port nil when unknown.
          if uri.default_port == uri.port
            uri.host
          else
            "#{uri.host}:#{uri.port}"
          end
        end

        def canonical_request http_method, uri, headers, content_sha256
          headers = headers.sort_by(&:first) # transforms to a sorted array of [key, value]

          [
            http_method,
            uri.path.empty? ? "/" : uri.path,
            build_canonical_querystring(uri.query || ""),
            headers.map { |k, v| "#{k}:#{v}\n" }.join, # Canonical headers
            headers.map(&:first).join(";"), # Signed headers
            content_sha256
          ].join("\n")
        end

        def sha256_hexdigest string
          OpenSSL::Digest::SHA256.hexdigest string
        end

        # Generates the canonical query string given a raw query string.
        # Logic is based on
        # https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
        # Code is from the AWS SDK for Ruby
        # https://github.com/aws/aws-sdk-ruby/blob/0ac3d0a393ed216290bfb5f0383380376f6fb1f1/gems/aws-sigv4/lib/aws-sigv4/signer.rb#L532
        def build_canonical_querystring query
          params = query.split "&"
          params = params.map { |p| p.include?("=") ? p : "#{p}=" }

          params.each.with_index.sort do |(a, a_offset), (b, b_offset)|
            a_name, a_value = a.split "="
            b_name, b_value = b.split "="
            if a_name == b_name
              if a_value == b_value
                a_offset <=> b_offset
              else
                a_value <=> b_value
              end
            else
              a_name <=> b_name
            end
          end.map(&:first).join("&")
        end
      end
    end
  end
end
