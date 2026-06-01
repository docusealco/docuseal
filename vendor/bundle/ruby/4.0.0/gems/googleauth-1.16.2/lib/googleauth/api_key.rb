# Copyright 2025 Google LLC
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
require "googleauth/credentials_loader"

module Google
  module Auth
    ##
    # Implementation of Google API Key authentication.
    #
    # API Keys are text strings. They don't have an associated JSON file.
    #
    # The end-user is managing their API Keys directly, not via
    # an authentication library.
    #
    # API Keys provide project information for an API request.
    # API Keys don't reference an IAM principal, they do not expire,
    # and cannot be refreshed.
    #
    class APIKeyCredentials
      include Google::Auth::BaseClient

      # @private Authorization header key
      API_KEY_HEADER = "x-goog-api-key".freeze

      # @private Environment variable containing API key
      API_KEY_VAR = "GOOGLE_API_KEY".freeze

      # @return [String] The API key
      attr_reader :api_key

      # @return [String] The universe domain of the universe
      #   this API key is for
      attr_accessor :universe_domain

      class << self
        # Creates an APIKeyCredentials from the environment.
        # Checks the ENV['GOOGLE_API_KEY'] variable.
        #
        # @param [String] _scope
        #  The scope to use for OAuth. Not used by API key auth.
        # @param [Hash] options
        #  The options to pass to the credentials instance
        #
        # @return [Google::Auth::APIKeyCredentials, nil]
        #  Credentials if the API key environment variable is present,
        #  nil otherwise
        def from_env _scope = nil, options = {}
          api_key = ENV[API_KEY_VAR]
          return nil if api_key.nil? || api_key.empty?
          new options.merge(api_key: api_key)
        end

        # Create the APIKeyCredentials.
        #
        # @param [Hash] options The credentials options
        # @option options [String] :api_key
        #   The API key to use for authentication
        # @option options [String] :universe_domain
        #   The universe domain of the universe this API key
        #   belongs to (defaults to googleapis.com)
        # @return [Google::Auth::APIKeyCredentials]
        def make_creds options = {}
          new options
        end
      end

      # Initialize the APIKeyCredentials.
      #
      # @param [Hash] options The credentials options
      # @option options [String] :api_key
      #   The API key to use for authentication
      # @option options [String] :universe_domain
      #   The universe domain of the universe this API key
      #   belongs to (defaults to googleapis.com)
      # @raise [ArgumentError] If the API key is nil or empty
      def initialize options = {}
        raise ArgumentError, "API key must be provided" if options[:api_key].nil? || options[:api_key].empty?
        @api_key = options[:api_key]
        @universe_domain = options[:universe_domain] || "googleapis.com"
      end

      # Determines if the credentials object has expired.
      # Since API keys don't expire, this always returns false.
      #
      # @param [Fixnum] _seconds
      #  The optional timeout in seconds since the last refresh
      # @return [Boolean]
      #  True if the token has expired, false otherwise.
      def expires_within? _seconds
        false
      end

      # Creates a duplicate of these credentials.
      #
      # @param [Hash] options Additional options for configuring the credentials
      # @return [Google::Auth::APIKeyCredentials]
      def duplicate options = {}
        self.class.new(
          api_key: options[:api_key] || @api_key,
          universe_domain: options[:universe_domain] || @universe_domain
        )
      end

      # Updates the provided hash with the API Key header.
      #
      # The `apply!` method modifies the provided hash in place, adding the
      # `x-goog-api-key` header with the API Key value.
      #
      # The API Key is hashed before being logged for security purposes.
      #
      # NB: this method typically would be called through `updater_proc`.
      # Some older clients call it directly though, so it has to be public.
      #
      # @param [Hash] a_hash The hash to which the API Key header should be added.
      #   This is typically a hash representing the request headers.  This hash
      #   will be modified in place.
      # @param [Hash] _opts  Additional options (currently not used).  Included
      #   for consistency with the `BaseClient` interface.
      # @return [Hash] The modified hash (the same hash passed as the `a_hash`
      #   argument).
      def apply! a_hash, _opts = {}
        a_hash[API_KEY_HEADER] = @api_key
        logger&.debug do
          hash = Digest::SHA256.hexdigest @api_key
          Google::Logging::Message.from message: "Sending API key auth token. (sha256:#{hash})"
        end
        a_hash
      end

      # For credentials that are initialized with a token without a principal,
      # the type of that token should be returned as a principal instead
      # @private
      # @return [Symbol] the token type in lieu of the principal
      def principal
        token_type
      end

      protected

      # The token type should be :api_key
      def token_type
        :api_key
      end

      # We don't need to fetch access tokens for API key auth
      def fetch_access_token! _options = {}
        nil
      end
    end
  end
end
