# Copyright 2017 Google, Inc.
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

require "forwardable"
require "json"
require "pathname"
require "signet/oauth_2/client"
require "multi_json"

require "googleauth/credentials_loader"
require "googleauth/errors"

module Google
  module Auth
    ##
    # Credentials is a high-level base class used by Google's API client
    # libraries to represent the authentication when connecting to an API.
    # In most cases, it is subclassed by API-specific credential classes that
    # can be instantiated by clients.
    #
    # **Important:** If you accept a credential configuration (credential
    # JSON/File/Stream) from an external source for authentication to Google
    # Cloud, you must validate it before providing it to any Google API or
    # library. Providing an unvalidated credential configuration to Google APIs
    # can compromise the security of your systems and data. For more
    # information, refer to [Validate credential configurations from external
    # sources](https://cloud.google.com/docs/authentication/external/externally-sourced-credentials).
    #
    # ## Options
    #
    # Credentials classes are configured with options that dictate default
    # values for parameters such as scope and audience. These defaults are
    # expressed as class attributes, and may differ from endpoint to endpoint.
    # Normally, an API client will provide subclasses specific to each
    # endpoint, configured with appropriate values.
    #
    # Note that these options inherit up the class hierarchy. If a particular
    # options is not set for a subclass, its superclass is queried.
    #
    # Some older users of this class set options via constants. This usage is
    # deprecated. For example, instead of setting the `AUDIENCE` constant on
    # your subclass, call the `audience=` method.
    #
    # ## Example
    #
    #     class MyCredentials < Google::Auth::Credentials
    #       # Set the default scope for these credentials
    #       self.scope = "http://example.com/my_scope"
    #     end
    #
    #     # creds is a credentials object suitable for Google API clients
    #     creds = MyCredentials.default
    #     creds.scope  # => ["http://example.com/my_scope"]
    #
    #     class SubCredentials < MyCredentials
    #       # Override the default scope for this subclass
    #       self.scope = "http://example.com/sub_scope"
    #     end
    #
    #     creds2 = SubCredentials.default
    #     creds2.scope  # => ["http://example.com/sub_scope"]
    #
    class Credentials # rubocop:disable Metrics/ClassLength
      ##
      # The default token credential URI to be used when none is provided during initialization.
      TOKEN_CREDENTIAL_URI = "https://oauth2.googleapis.com/token".freeze

      ##
      # The default target audience ID to be used when none is provided during initialization.
      AUDIENCE = "https://oauth2.googleapis.com/token".freeze

      @audience = @scope = @target_audience = @env_vars = @paths = @token_credential_uri = nil

      ##
      # The default token credential URI to be used when none is provided during initialization.
      # The URI is the authorization server's HTTP endpoint capable of issuing tokens and
      # refreshing expired tokens.
      #
      # @return [String]
      #
      def self.token_credential_uri
        lookup_auth_param :token_credential_uri do
          lookup_local_constant :TOKEN_CREDENTIAL_URI
        end
      end

      ##
      # Set the default token credential URI to be used when none is provided during initialization.
      #
      # @param [String] new_token_credential_uri
      #
      def self.token_credential_uri= new_token_credential_uri
        @token_credential_uri = new_token_credential_uri
      end

      ##
      # The default target audience ID to be used when none is provided during initialization.
      # Used only by the assertion grant type.
      #
      # @return [String]
      #
      def self.audience
        lookup_auth_param :audience do
          lookup_local_constant :AUDIENCE
        end
      end

      ##
      # Sets the default target audience ID to be used when none is provided during initialization.
      #
      # @param [String] new_audience
      #
      def self.audience= new_audience
        @audience = new_audience
      end

      ##
      # The default scope to be used when none is provided during initialization.
      # A scope is an access range defined by the authorization server.
      # The scope can be a single value or a list of values.
      #
      # Either {#scope} or {#target_audience}, but not both, should be non-nil.
      # If {#scope} is set, this credential will produce access tokens.
      # If {#target_audience} is set, this credential will produce ID tokens.
      #
      # @return [String, Array<String>, nil]
      #
      def self.scope
        lookup_auth_param :scope do
          vals = lookup_local_constant :SCOPE
          vals ? Array(vals).flatten.uniq : nil
        end
      end

      ##
      # Sets the default scope to be used when none is provided during initialization.
      #
      # Either {#scope} or {#target_audience}, but not both, should be non-nil.
      # If {#scope} is set, this credential will produce access tokens.
      # If {#target_audience} is set, this credential will produce ID tokens.
      #
      # @param [String, Array<String>, nil] new_scope
      #
      def self.scope= new_scope
        new_scope = Array new_scope unless new_scope.nil?
        @scope = new_scope
      end

      ##
      # The default final target audience for ID tokens, to be used when none
      # is provided during initialization.
      #
      # Either {#scope} or {#target_audience}, but not both, should be non-nil.
      # If {#scope} is set, this credential will produce access tokens.
      # If {#target_audience} is set, this credential will produce ID tokens.
      #
      # @return [String, nil]
      #
      def self.target_audience
        lookup_auth_param :target_audience
      end

      ##
      # Sets the default final target audience for ID tokens, to be used when none
      # is provided during initialization.
      #
      # Either {#scope} or {#target_audience}, but not both, should be non-nil.
      # If {#scope} is set, this credential will produce access tokens.
      # If {#target_audience} is set, this credential will produce ID tokens.
      #
      # @param [String, nil] new_target_audience
      #
      def self.target_audience= new_target_audience
        @target_audience = new_target_audience
      end

      ##
      # The environment variables to search for credentials. Values can either be a file path to the
      # credentials file, or the JSON contents of the credentials file.
      # The env_vars will never be nil. If there are no vars, the empty array is returned.
      #
      # @return [Array<String>]
      #
      def self.env_vars
        env_vars_internal || []
      end

      ##
      # @private
      # Internal recursive lookup for env_vars.
      #
      def self.env_vars_internal
        lookup_auth_param :env_vars, :env_vars_internal do
          # Pull values when PATH_ENV_VARS or JSON_ENV_VARS constants exists.
          path_env_vars = lookup_local_constant :PATH_ENV_VARS
          json_env_vars = lookup_local_constant :JSON_ENV_VARS
          (Array(path_env_vars) + Array(json_env_vars)).flatten.uniq if path_env_vars || json_env_vars
        end
      end

      ##
      # Sets the environment variables to search for credentials.
      # Setting to `nil` "unsets" the value, and defaults to the superclass
      # (or to the empty array if there is no superclass).
      #
      # @param [String, Array<String>, nil] new_env_vars
      #
      def self.env_vars= new_env_vars
        new_env_vars = Array new_env_vars unless new_env_vars.nil?
        @env_vars = new_env_vars
      end

      ##
      # The file paths to search for credentials files.
      # The paths will never be nil. If there are no paths, the empty array is returned.
      #
      # @return [Array<String>]
      #
      def self.paths
        paths_internal || []
      end

      ##
      # @private
      # Internal recursive lookup for paths.
      #
      def self.paths_internal
        lookup_auth_param :paths, :paths_internal do
          # Pull in values if the DEFAULT_PATHS constant exists.
          vals = lookup_local_constant :DEFAULT_PATHS
          vals ? Array(vals).flatten.uniq : nil
        end
      end

      ##
      # Set the file paths to search for credentials files.
      # Setting to `nil` "unsets" the value, and defaults to the superclass
      # (or to the empty array if there is no superclass).
      #
      # @param [String, Array<String>, nil] new_paths
      #
      def self.paths= new_paths
        new_paths = Array new_paths unless new_paths.nil?
        @paths = new_paths
      end

      ##
      # @private
      # Return the given parameter value, defaulting up the class hierarchy.
      #
      # First returns the value of the instance variable, if set.
      # Next, calls the given block if provided. (This is generally used to
      # look up legacy constant-based values.)
      # Otherwise, calls the superclass method if present.
      # Returns nil if all steps fail.
      #
      # @param name [Symbol] The parameter name
      # @param method_name [Symbol] The lookup method name, if different
      # @return [Object] The value
      #
      def self.lookup_auth_param name, method_name = name
        val = instance_variable_get :"@#{name}"
        val = yield if val.nil? && block_given?
        return val unless val.nil?
        return superclass.send method_name if superclass.respond_to? method_name
        nil
      end

      ##
      # @private
      # Return the value of the given constant if it is defined directly in
      # this class, or nil if not.
      #
      # @param [Symbol] Name of the constant
      # @return [Object] The value
      #
      def self.lookup_local_constant name
        const_defined?(name, false) ? const_get(name) : nil
      end

      ##
      # The Signet::OAuth2::Client object the Credentials instance is using.
      #
      # @return [Signet::OAuth2::Client]
      #
      attr_accessor :client

      ##
      # Identifier for the project the client is authenticating with.
      #
      # @return [String]
      #
      attr_reader :project_id

      ##
      # Identifier for a separate project used for billing/quota, if any.
      #
      # @return [String,nil]
      #
      attr_reader :quota_project_id

      # @private Temporary; remove when universe domain metadata endpoint is stable (see b/349488459).
      def disable_universe_domain_check
        return false unless @client.respond_to? :disable_universe_domain_check
        @client.disable_universe_domain_check
      end

      # @private Delegate client methods to the client object.
      extend Forwardable

      ##
      # @!attribute [r] token_credential_uri
      #   @return [String] The token credential URI. The URI is the authorization server's HTTP
      #     endpoint capable of issuing tokens and refreshing expired tokens.
      #
      # @!attribute [r] audience
      #   @return [String] The target audience ID when issuing assertions. Used only by the
      #     assertion grant type.
      #
      # @!attribute [r] scope
      #   @return [String, Array<String>] The scope for this client. A scope is an access range
      #     defined by the authorization server. The scope can be a single value or a list of values.
      #
      # @!attribute [r] issuer
      #   @return [String] The issuer ID associated with this client.
      #
      # @!attribute [r] signing_key
      #   @return [String, OpenSSL::PKey] The signing key associated with this client.
      #
      # @!attribute [r] updater_proc
      #   @return [Proc] Returns a reference to the {Signet::OAuth2::Client#apply} method,
      #     suitable for passing as a closure.
      #
      # @!attribute [r] target_audience
      #   @return [String] The final target audience for ID tokens returned by this credential.
      #
      # @!attribute [rw] universe_domain
      #   @return [String] The universe domain issuing these credentials.
      #
      # @!attribute [rw] logger
      #   @return [Logger] The logger used to log credential operations such as token refresh.
      #
      def_delegators :@client,
                     :token_credential_uri, :audience,
                     :scope, :issuer, :signing_key, :updater_proc, :target_audience,
                     :universe_domain, :universe_domain=, :logger, :logger=

      ##
      # Creates a new Credentials instance with the provided auth credentials, and with the default
      # values configured on the class.
      #
      # @param [String, Pathname, Hash, Google::Auth::BaseClient] source_creds
      #   The source of credentials. It can be provided as one of the following:
      #
      #   * The path to a JSON keyfile (as a `String` or a `Pathname`)
      #   * The contents of a JSON keyfile (as a `Hash`)
      #   * A `Google::Auth::BaseClient` credentials object, including but not limited to
      #       a `Signet::OAuth2::Client` object.
      #   * Any credentials object that supports the methods this wrapper delegates to an inner client.
      #
      #   If this parameter is an object (`Signet::OAuth2::Client` or other) it will be used as an inner client.
      #   Otherwise the inner client will be constructed from the JSON keyfile or the contens of the hash.
      #
      # @param [Hash] options
      #   The options for configuring this wrapper credentials object and the inner client.
      #   The options hash is used in two ways:
      #
      #   1. **Configuring the wrapper object:** Some options are used to directly
      #      configure the wrapper `Credentials` instance. These include:
      #
      #     * `:project_id` (and optionally `:project`) - the project identifier for the client
      #     * `:quota_project_id` - the quota project identifier for the client
      #     * `:logger` - the logger used to log credential operations such as token refresh.
      #
      #   2. **Configuring the inner client:** When the `source_creds` parameter
      #      is a `String` or `Hash`, a new `Signet::OAuth2::Client` is created
      #      internally. The following options are used to configure this inner client:
      #
      #     * `:scope` - the scope for the client
      #     * `:target_audience` - the target audience for the client
      #
      #   Any other options in the `options` hash are passed directly to the
      #   inner client constructor. This allows you to configure additional
      #   parameters of the `Signet::OAuth2::Client`, such as connection parameters,
      #   timeouts, etc.
      #
      # @raise [Google::Auth::InitializationError] If source_creds is nil
      # @raise [ArgumentError] If both scope and target_audience are specified
      #
      def initialize source_creds, options = {}
        if source_creds.nil?
          raise InitializationError,
                "The source credentials passed to Google::Auth::Credentials.new were nil."
        end

        options = symbolize_hash_keys options
        @project_id = options[:project_id] || options[:project]
        @quota_project_id = options[:quota_project_id]
        case source_creds
        when String, Pathname
          update_from_filepath source_creds, options
        when Hash
          update_from_hash source_creds, options
        else
          update_from_client source_creds
        end
        setup_logging logger: options.fetch(:logger, :default)
        @project_id ||= CredentialsLoader.load_gcloud_project_id
        @env_vars = nil
        @paths = nil
        @scope = nil
      end

      ##
      # Creates a new Credentials instance with auth credentials acquired by searching the
      # environment variables and paths configured on the class, and with the default values
      # configured on the class.
      #
      # The auth credentials are searched for in the following order:
      #
      # 1. configured environment variables (see {Credentials.env_vars})
      # 2. configured default file paths (see {Credentials.paths})
      # 3. application default (see {Google::Auth.get_application_default})
      #
      # @param [Hash] options
      #   The options for configuring the credentials instance. The following is supported:
      #
      #   * +:scope+ - the scope for the client
      #   * +"project_id"+ (and optionally +"project"+) - the project identifier for the client
      #   * +:connection_builder+ - the connection builder to use for the client
      #   * +:default_connection+ - the default connection to use for the client
      #
      # @return [Credentials]
      #
      def self.default options = {}
        # First try to find keyfile file or json from environment variables.
        client = from_env_vars options

        # Second try to find keyfile file from known file paths.
        client ||= from_default_paths options

        # Finally get instantiated client from Google::Auth
        client ||= from_application_default options
        client
      end

      ##
      # @private Lookup Credentials from environment variables.
      def self.from_env_vars options
        env_vars.each do |env_var|
          str = ENV[env_var]
          next if str.nil?
          io =
            if ::File.file? str
              ::StringIO.new ::File.read str
            else
              json = ::JSON.parse str rescue nil
              json ? ::StringIO.new(str) : nil
            end
          next if io.nil?
          return from_io io, options
        end
        nil
      end

      ##
      # @private Lookup Credentials from default file paths.
      def self.from_default_paths options
        paths.each do |path|
          next unless path && ::File.file?(path)
          io = ::StringIO.new ::File.read path
          return from_io io, options
        end
        nil
      end

      ##
      # @private Lookup Credentials using Google::Auth.get_application_default.
      def self.from_application_default options
        scope = options[:scope] || self.scope
        auth_opts = {
          token_credential_uri:   options[:token_credential_uri] || token_credential_uri,
          audience:               options[:audience] || audience,
          target_audience:        options[:target_audience] || target_audience,
          enable_self_signed_jwt: options[:enable_self_signed_jwt] && options[:scope].nil?
        }
        client = Google::Auth.get_application_default scope, auth_opts
        new client, options
      end

      # @private Read credentials from a JSON stream.
      def self.from_io io, options
        creds_input = {
          json_key_io:            io,
          scope:                  options[:scope] || scope,
          target_audience:        options[:target_audience] || target_audience,
          enable_self_signed_jwt: options[:enable_self_signed_jwt] && options[:scope].nil?,
          token_credential_uri:   options[:token_credential_uri] || token_credential_uri,
          audience:               options[:audience] || audience
        }

        # Determine the class, which consumes the IO stream
        json_key, clz = Google::Auth::DefaultCredentials.determine_creds_class creds_input[:json_key_io]

        # Re-serialize the parsed JSON and replace the IO stream in creds_input
        creds_input[:json_key_io] = StringIO.new MultiJson.dump(json_key)

        client = clz.make_creds creds_input
        options = options.select { |k, _v| k == :logger }
        new client, options
      end

      # @private
      # Initializes the Signet client.
      def self.init_client hash, options = {}
        options = update_client_options options
        io = StringIO.new JSON.generate hash

        # Determine the class, which consumes the IO stream
        json_key, clz = Google::Auth::DefaultCredentials.determine_creds_class io

        # Re-serialize the parsed JSON and create a new IO stream.
        new_io = StringIO.new MultiJson.dump(json_key)

        clz.make_creds options.merge!(json_key_io: new_io)
      end

      # @private
      # Updates client options with defaults from the credential class
      #
      # @param [Hash] options Options to update
      # @return [Hash] Updated options hash
      # @raise [ArgumentError] If both scope and target_audience are specified
      def self.update_client_options options
        options = options.dup

        # options have higher priority over constructor defaults
        options[:token_credential_uri] ||= token_credential_uri
        options[:audience] ||= audience
        options[:scope] ||= scope
        options[:target_audience] ||= target_audience

        if !Array(options[:scope]).empty? && options[:target_audience]
          raise ArgumentError, "Cannot specify both scope and target_audience"
        end
        options.delete :scope unless options[:target_audience].nil?

        options
      end

      private_class_method :from_env_vars,
                           :from_default_paths,
                           :from_application_default,
                           :from_io

      # Creates a duplicate of these credentials. This method tries to create the duplicate of the
      # wrapped credentials if they support duplication and use them as is if they don't.
      #
      # The wrapped credentials are typically `Signet::OAuth2::Client` objects and they keep
      # the transient state (token, refresh token, etc). The duplication discards that state,
      # allowing e.g. to get the token with a different scope.
      #
      # @param options [Hash] Overrides for the credentials parameters.
      #
      #   The options hash is used in two ways:
      #
      #   1. **Configuring the duplicate of the wrapper object:** Some options are used to directly
      #      configure the wrapper `Credentials` instance. These include:
      #
      #     * `:project_id` (and optionally `:project`) - the project identifier for the credentials
      #     * `:quota_project_id` - the quota project identifier for the credentials
      #
      #   2. **Configuring the duplicate of the inner client:** If the inner client supports duplication
      #   the options hash is passed to it. This allows for configuration of additional parameters,
      #   most importantly (but not limited to) the following:
      #
      #     * `:scope` - the scope for the client
      #
      # @return [Credentials]
      def duplicate options = {}
        options = deep_hash_normalize options

        options = {
          project_id: @project_id,
          quota_project_id: @quota_project_id
        }.merge(options)

        new_client = if @client.respond_to? :duplicate
                       @client.duplicate options
                     else
                       @client
                     end

        self.class.new new_client, options
      end

      protected

      # Verify that the keyfile argument is a file.
      #
      # @param [String] keyfile Path to the keyfile
      # @raise [Google::Auth::InitializationError] If the keyfile does not exist
      def verify_keyfile_exists! keyfile
        exists = ::File.file? keyfile
        raise InitializationError, "The keyfile '#{keyfile}' is not a valid file." unless exists
      end

      # returns a new Hash with string keys instead of symbol keys.
      def stringify_hash_keys hash
        hash.to_h.transform_keys(&:to_s)
      end

      # returns a new Hash with symbol keys instead of string keys.
      def symbolize_hash_keys hash
        hash.to_h.transform_keys(&:to_sym)
      end

      def update_from_client client
        @project_id ||= client.project_id if client.respond_to? :project_id
        @quota_project_id ||= client.quota_project_id if client.respond_to? :quota_project_id
        @client = client
      end
      alias update_from_signet update_from_client

      def update_from_hash hash, options
        hash = stringify_hash_keys hash
        hash["scope"] ||= options[:scope]
        hash["target_audience"] ||= options[:target_audience]
        @project_id ||= hash["project_id"] || hash["project"]
        @quota_project_id ||= hash["quota_project_id"]
        @client = self.class.init_client hash, options
      end

      def update_from_filepath path, options
        verify_keyfile_exists! path
        json = JSON.parse ::File.read(path)
        json["scope"] ||= options[:scope]
        json["target_audience"] ||= options[:target_audience]
        @project_id ||= json["project_id"] || json["project"]
        @quota_project_id ||= json["quota_project_id"]
        @client = self.class.init_client json, options
      end

      def setup_logging logger: :default
        return unless @client.respond_to? :logger=
        logging_env = ENV["GOOGLE_SDK_RUBY_LOGGING_GEMS"].to_s.downcase
        if ["false", "none"].include? logging_env
          logger = nil
        elsif @client.logger
          logger = @client.logger
        elsif logger == :default
          logger = nil
          if ["true", "all"].include?(logging_env) || logging_env.split(",").include?("googleauth")
            formatter = Google::Logging::StructuredFormatter.new if Google::Cloud::Env.get.logging_agent_expected?
            logger = Logger.new $stderr, progname: "googleauth", formatter: formatter
          end
        end
        @client.logger = logger
      end

      private

      # Convert all keys in this hash (nested) to symbols for uniform retrieval
      def recursive_hash_normalize_keys val
        if val.is_a? Hash
          deep_hash_normalize val
        else
          val
        end
      end

      def deep_hash_normalize old_hash
        sym_hash = {}
        old_hash&.each { |k, v| sym_hash[k.to_sym] = recursive_hash_normalize_keys v }
        sym_hash
      end
    end
  end
end
