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

require "google-cloud-env"
require "googleauth/errors"
require "googleauth/signet"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    NO_METADATA_SERVER_ERROR = <<~ERROR.freeze
      Error code 404 trying to get security access token
      from Compute Engine metadata for the default service account. This
      may be because the virtual machine instance does not have permission
      scopes specified.
    ERROR
    UNEXPECTED_ERROR_SUFFIX = <<~ERROR.freeze
      trying to get security access token from Compute Engine metadata for
      the default service account
    ERROR

    # Extends Signet::OAuth2::Client so that the auth token is obtained from
    # the GCE metadata server.
    class GCECredentials < Signet::OAuth2::Client
      # @private Unused and deprecated but retained to prevent breaking changes
      DEFAULT_METADATA_HOST = "169.254.169.254".freeze

      # @private Unused and deprecated but retained to prevent breaking changes
      COMPUTE_AUTH_TOKEN_URI =
        "http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token".freeze
      # @private Unused and deprecated but retained to prevent breaking changes
      COMPUTE_ID_TOKEN_URI =
        "http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/identity".freeze
      # @private Unused and deprecated but retained to prevent breaking changes
      COMPUTE_CHECK_URI = "http://169.254.169.254".freeze

      class << self
        # @private Unused and deprecated
        def metadata_host
          ENV.fetch "GCE_METADATA_HOST", DEFAULT_METADATA_HOST
        end

        # @private Unused and deprecated
        def compute_check_uri
          "http://#{metadata_host}".freeze
        end

        # @private Unused and deprecated
        def compute_auth_token_uri
          "#{compute_check_uri}/computeMetadata/v1/instance/service-accounts/default/token".freeze
        end

        # @private Unused and deprecated
        def compute_id_token_uri
          "#{compute_check_uri}/computeMetadata/v1/instance/service-accounts/default/identity".freeze
        end

        # Detect if this appear to be a GCE instance, by checking if metadata
        # is available.
        # The parameters are deprecated and unused.
        def on_gce? _options = {}, _reload = false # rubocop:disable Style/OptionalBooleanParameter
          Google::Cloud.env.metadata?
        end

        def reset_cache
          Google::Cloud.env.compute_metadata.reset_existence!
          Google::Cloud.env.compute_metadata.cache.expire_all!
        end
        alias unmemoize_all reset_cache
      end

      # @private Temporary; remove when universe domain metadata endpoint is stable (see b/349488459).
      attr_accessor :disable_universe_domain_check

      # Construct a GCECredentials
      def initialize options = {}
        # Override the constructor to remember whether the universe domain was
        # overridden by a constructor argument.
        @universe_domain_overridden = options["universe_domain"] || options[:universe_domain]
        # TODO: Remove when universe domain metadata endpoint is stable (see b/349488459).
        @disable_universe_domain_check = true
        super options
      end

      # Creates a duplicate of these credentials
      # without the Signet::OAuth2::Client-specific
      # transient state (e.g. cached tokens)
      #
      # @param options [Hash] Overrides for the credentials parameters.
      #   The following keys are recognized in addition to keys in the
      #   Signet::OAuth2::Client
      #   * `:universe_domain_overridden` Whether the universe domain was
      #     overriden during credentials creation
      def duplicate options = {}
        options = deep_hash_normalize options
        super(
          {
            universe_domain_overridden: @universe_domain_overridden
          }.merge(options)
        )
      end

      # @private
      # Overrides universe_domain getter to fetch lazily if it hasn't been
      # fetched yet. This is necessary specifically for Compute Engine because
      # the universe comes from the metadata service, and isn't known
      # immediately on credential construction. All other credential types read
      # the universe from their json key or other immediate input.
      def universe_domain
        value = super
        return value unless value.nil?
        fetch_access_token!
        super
      end

      # Overrides the super class method to change how access tokens are
      # fetched.
      #
      # @param [Hash] _options Options for token fetch (not used)
      # @return [Hash] The token data hash
      # @raise [Google::Auth::UnexpectedStatusError] On unexpected HTTP status codes
      # @raise [Google::Auth::AuthorizationError] If metadata server is unavailable or returns error
      def fetch_access_token _options = {}
        query, entry = build_metadata_request_params
        begin
          log_fetch_query
          resp = Google::Cloud.env.lookup_metadata_response "instance", entry, query: query
          log_fetch_resp resp
          handle_metadata_response resp
        rescue Google::Cloud::Env::MetadataServerNotResponding => e
          log_fetch_err e
          raise AuthorizationError.with_details(
            e.message,
            credential_type_name: self.class.name,
            principal: principal
          )
        end
      end

      # Destructively updates these credentials.
      #
      # This method is called by `Signet::OAuth2::Client`'s constructor
      #
      # @param options [Hash] Overrides for the credentials parameters.
      #   The following keys are recognized in addition to keys in the
      #   Signet::OAuth2::Client
      #   * `:universe_domain_overridden` Whether the universe domain was
      #     overriden during credentials creation
      # @return [Google::Auth::GCECredentials]
      def update! options = {}
        # Normalize all keys to symbols to allow indifferent access.
        options = deep_hash_normalize options

        @universe_domain_overridden = options[:universe_domain_overridden] if options.key? :universe_domain_overridden

        super(options)

        self
      end

      # Returns the principal identifier for GCE credentials
      # @private
      # @return [Symbol] :gce to represent Google Compute Engine identity
      def principal
        :gce_metadata
      end

      private

      # @private
      # Builds query parameters and endpoint for metadata request
      # @return [Array] The query parameters and endpoint path
      def build_metadata_request_params
        query, entry =
          if token_type == :id_token
            [{ "audience" => target_audience, "format" => "full" }, "service-accounts/default/identity"]
          else
            [{}, "service-accounts/default/token"]
          end
        query[:scopes] = Array(scope).join "," if scope
        [query, entry]
      end

      # @private
      # Handles the response from the metadata server
      # @param [Google::Cloud::Env::MetadataResponse] resp The metadata server response
      # @return [Hash] The token hash on success
      # @raise [Google::Auth::UnexpectedStatusError, Google::Auth::AuthorizationError] On error
      def handle_metadata_response resp
        case resp.status
        when 200
          build_token_hash resp.body, resp.headers["content-type"], resp.retrieval_monotonic_time
        when 403, 500
          raise Signet::UnexpectedStatusError, "Unexpected error code #{resp.status} #{UNEXPECTED_ERROR_SUFFIX}"
        when 404
          raise Signet::AuthorizationError, NO_METADATA_SERVER_ERROR
        else
          raise Signet::AuthorizationError, "Unexpected error code #{resp.status} #{UNEXPECTED_ERROR_SUFFIX}"
        end
      end

      def log_fetch_query
        if token_type == :id_token
          logger&.info do
            Google::Logging::Message.from(
              message: "Requesting id token from MDS with aud=#{target_audience}",
              "credentialsId" => object_id
            )
          end
        else
          logger&.info do
            Google::Logging::Message.from(
              message: "Requesting access token from MDS",
              "credentialsId" => object_id
            )
          end
        end
      end

      def log_fetch_resp resp
        logger&.info do
          Google::Logging::Message.from(
            message: "Received #{resp.status} from MDS",
            "credentialsId" => object_id
          )
        end
      end

      def log_fetch_err _err
        logger&.info do
          Google::Logging::Message.from(
            message: "MDS did not respond to token request",
            "credentialsId" => object_id
          )
        end
      end

      # Constructs a token hash from the metadata server response
      #
      # @private
      # @param [String] body The response body from the metadata server
      # @param [String] content_type The content type of the response
      # @param [Float] retrieval_time The monotonic time when the response was retrieved
      #
      # @return [Hash] A hash containing:
      #   - access_token/id_token: The actual token depending on what was requested
      #   - token_type: The type of token (usually "Bearer")
      #   - expires_in: Seconds until token expiration (adjusted for freshness)
      #   - universe_domain: The universe domain for the token (if not overridden)
      def build_token_hash body, content_type, retrieval_time
        hash =
          if ["text/html", "application/text"].include? content_type
            parse_encoded_token body
          else
            Signet::OAuth2.parse_credentials body, content_type
          end
        add_universe_domain_to hash
        adjust_for_stale_expires_in hash, retrieval_time
        hash
      end

      def parse_encoded_token body
        hash = { token_type.to_s => body }
        if token_type == :id_token
          expires_at = expires_at_from_id_token body
          hash["expires_at"] = expires_at if expires_at
        end
        hash
      end

      def add_universe_domain_to hash
        return if @universe_domain_overridden
        universe_domain =
          if disable_universe_domain_check
            # TODO: Remove when universe domain metadata endpoint is stable (see b/349488459).
            "googleapis.com"
          else
            Google::Cloud.env.lookup_metadata "universe", "universe-domain"
          end
        universe_domain = "googleapis.com" if !universe_domain || universe_domain.empty?
        hash["universe_domain"] = universe_domain.strip
      end

      # The response might have been cached, which means expires_in might be
      # stale. Update it based on the time since the data was retrieved.
      # We also ensure expires_in is conservative; subtracting at least 1
      # second to offset any skew from metadata server latency.
      def adjust_for_stale_expires_in hash, retrieval_time
        return unless hash["expires_in"].is_a? Numeric
        offset = 1 + (Process.clock_gettime(Process::CLOCK_MONOTONIC) - retrieval_time).round
        hash["expires_in"] -= offset if offset.positive?
        hash["expires_in"] = 0 if hash["expires_in"].negative?
      end
    end
  end
end
