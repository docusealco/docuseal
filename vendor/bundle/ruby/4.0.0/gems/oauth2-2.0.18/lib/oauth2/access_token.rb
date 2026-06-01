# frozen_string_literal: true

# :nocov:
begin
  # The first version of hashie that has a version file was 1.1.0
  # The first version of hashie that required the version file at runtime was 3.2.0
  # If it has already been loaded then this is very low cost, as Kernel.require uses maintains a cache
  # If this it hasn't this will work to get it loaded, and then we will be able to use
  #   defined?(Hashie::Version)
  # as a test.
  # TODO: get rid this mess when we drop Hashie < 3.2, as Hashie will self-load its version then
  require "hashie/version"
rescue LoadError
  nil
end
# :nocov:

module OAuth2
  class AccessToken # rubocop:disable Metrics/ClassLength
    TOKEN_KEYS_STR = %w[access_token id_token token accessToken idToken].freeze
    TOKEN_KEYS_SYM = %i[access_token id_token token accessToken idToken].freeze
    TOKEN_KEY_LOOKUP = TOKEN_KEYS_STR + TOKEN_KEYS_SYM

    include FilteredAttributes

    attr_reader :client, :token, :expires_in, :expires_at, :expires_latency, :params
    attr_accessor :options, :refresh_token, :response
    filtered_attributes :token, :refresh_token

    class << self
      # Initializes an AccessToken from a Hash
      #
      # @param [OAuth2::Client] client the OAuth2::Client instance
      # @param [Hash] hash a hash containing the token and other properties
      # @option hash [String] 'access_token' the access token value
      # @option hash [String] 'id_token' alternative key for the access token value
      # @option hash [String] 'token' alternative key for the access token value
      # @option hash [String] 'refresh_token' (optional) the refresh token value
      # @option hash [Integer, String] 'expires_in' (optional) number of seconds until token expires
      # @option hash [Integer, String] 'expires_at' (optional) epoch time in seconds when token expires
      # @option hash [Integer, String] 'expires_latency' (optional) seconds to reduce token validity by
      #
      # @return [OAuth2::AccessToken] the initialized AccessToken
      #
      # @note The method will use the first found token key in the following order:
      #   'access_token', 'id_token', 'token' (or their symbolic versions)
      # @note If multiple token keys are present, a warning will be issued unless
      #   OAuth2.config.silence_extra_tokens_warning is true
      # @note If no token keys are present, a warning will be issued unless
      #   OAuth2.config.silence_no_tokens_warning is true
      # @note For "soon-to-expire"/"clock-skew" functionality see the `:expires_latency` option.
      # @note If snaky key conversion is being used, token_name needs to match the converted key.
      #
      # @example
      #   hash = { 'access_token' => 'token_value', 'refresh_token' => 'refresh_value' }
      #   access_token = OAuth2::AccessToken.from_hash(client, hash)
      def from_hash(client, hash)
        fresh = hash.dup
        # If token_name is present, then use that key name
        key =
          if fresh.key?(:token_name)
            t_key = fresh[:token_name]
            no_tokens_warning(fresh, t_key)
            t_key
          else
            # Otherwise, if one of the supported default keys is present, use whichever has precedence
            supported_keys = TOKEN_KEY_LOOKUP & fresh.keys
            t_key = supported_keys[0]
            extra_tokens_warning(supported_keys, t_key)
            t_key
          end
        # :nocov:
        # TODO: Get rid of this branching logic when dropping Hashie < v3.2
        token = if !defined?(Hashie::VERSION) # i.e. <= "1.1.0"; the first Hashie to ship with a VERSION constant
          warn("snaky_hash and oauth2 will drop support for Hashie v0 in the next major version. Please upgrade to a modern Hashie.")
          # There is a bug in Hashie v0, which is accounts for.
          fresh.delete(key) || fresh[key] || ""
        else
          fresh.delete(key) || ""
        end
        # :nocov:
        new(client, token, fresh)
      end

      # Initializes an AccessToken from a key/value application/x-www-form-urlencoded string
      #
      # @param [Client] client the OAuth2::Client instance
      # @param [String] kvform the application/x-www-form-urlencoded string
      # @return [AccessToken] the initialized AccessToken
      def from_kvform(client, kvform)
        from_hash(client, Rack::Utils.parse_query(kvform))
      end

    private

      # Having too many is sus, and may lead to bugs. Having none is fine (e.g. refresh flow doesn't need a token).
      def extra_tokens_warning(supported_keys, key)
        return if OAuth2.config.silence_extra_tokens_warning
        return if supported_keys.length <= 1

        warn("OAuth2::AccessToken.from_hash: `hash` contained more than one 'token' key (#{supported_keys}); using #{key.inspect}.")
      end

      def no_tokens_warning(hash, key)
        return if OAuth2.config.silence_no_tokens_warning
        return if key && hash.key?(key)

        warn(%[
OAuth2::AccessToken#from_hash key mismatch.
Custom token_name (#{key}) is not found in (#{hash.keys})
You may need to set `snaky: false`. See inline documentation for more info.
        ])
      end
    end

    # Initialize an AccessToken
    #
    # @note For "soon-to-expire"/"clock-skew" functionality see the `:expires_latency` option.
    # @note If no token is provided, the AccessToken will be considered invalid.
    #   This is to prevent the possibility of a token being accidentally
    #   created with no token value.
    #   If you want to create an AccessToken with no token value,
    #   you can pass in an empty string or nil for the token value.
    #   If you want to create an AccessToken with no token value and
    #   no refresh token, you can pass in an empty string or nil for the
    #   token value and nil for the refresh token, and `raise_errors: false`.
    #
    # @param [Client] client the OAuth2::Client instance
    # @param [String] token the Access Token value (optional, may not be used in refresh flows)
    # @param [Hash] opts the options to create the Access Token with
    # @option opts [String] :refresh_token (nil) the refresh_token value
    # @option opts [FixNum, String] :expires_in (nil) the number of seconds in which the AccessToken will expire
    # @option opts [FixNum, String] :expires_at (nil) the epoch time in seconds in which AccessToken will expire
    # @option opts [FixNum, String] :expires_latency (nil) the number of seconds by which AccessToken validity will be reduced to offset latency, @version 2.0+
    # @option opts [Symbol, Hash, or callable] :mode (:header) the transmission mode of the Access Token parameter value:
    #    either one of :header, :body or :query; or a Hash with verb symbols as keys mapping to one of these symbols
    #    (e.g., `{get: :query, post: :header, delete: :header}`); or a callable that accepts a request-verb parameter
    #    and returns one of these three symbols.
    # @option opts [String] :header_format ('Bearer %s') the string format to use for the Authorization header
    #
    # @example Verb-dependent Hash mode
    #   # Send token in query for GET, in header for POST/DELETE, in body for PUT/PATCH
    #   OAuth2::AccessToken.new(client, token, mode: {get: :query, post: :header, delete: :header, put: :body, patch: :body})
    # @option opts [String] :param_name ('access_token') the parameter name to use for transmission of the
    #    Access Token value in :body or :query transmission mode
    # @option opts [String] :token_name (nil) the name of the response parameter that identifies the access token
    #    When nil one of TOKEN_KEY_LOOKUP will be used
    def initialize(client, token, opts = {})
      @client = client
      @token = token.to_s
      opts = opts.dup
      %i[refresh_token expires_in expires_at expires_latency].each do |arg|
        instance_variable_set("@#{arg}", opts.delete(arg) || opts.delete(arg.to_s))
      end
      no_tokens = (@token.nil? || @token.empty?) && (@refresh_token.nil? || @refresh_token.empty?)
      if no_tokens
        if @client.options[:raise_errors]
          raise Error.new({
            error: "OAuth2::AccessToken has no token",
            error_description: "Options are: #{opts.inspect}",
          })
        elsif !OAuth2.config.silence_no_tokens_warning
          warn("OAuth2::AccessToken has no token")
        end
      end
      # @option opts [Fixnum, String] :expires is deprecated
      @expires_in ||= opts.delete("expires")
      @expires_in &&= @expires_in.to_i
      @expires_at &&= convert_expires_at(@expires_at)
      @expires_latency &&= @expires_latency.to_i
      @expires_at ||= Time.now.to_i + @expires_in if @expires_in && !@expires_in.zero?
      @expires_at -= @expires_latency if @expires_latency
      @options = {
        mode: opts.delete(:mode) || :header,
        header_format: opts.delete(:header_format) || "Bearer %s",
        param_name: opts.delete(:param_name) || "access_token",
      }
      @options[:token_name] = opts.delete(:token_name) if opts.key?(:token_name)

      @params = opts
    end

    # Indexer to additional params present in token response
    #
    # @param [String] key entry key to Hash
    def [](key)
      @params[key]
    end

    # Whether the token expires
    #
    # @return [Boolean]
    def expires?
      !!@expires_at
    end

    # Check if token is expired
    #
    # @return [Boolean] true if the token is expired, false otherwise
    def expired?
      expires? && (expires_at <= Time.now.to_i)
    end

    # Refreshes the current Access Token
    #
    # @param [Hash] params additional params to pass to the refresh token request
    # @param [Hash] access_token_opts options that will be passed to the AccessToken initialization
    #
    # @yield [opts] The block to modify the refresh token request options
    # @yieldparam [Hash] opts The options hash that can be modified
    #
    # @return [OAuth2::AccessToken] a new AccessToken instance
    #
    # @note current token's options are carried over to the new AccessToken
    def refresh(params = {}, access_token_opts = {}, &block)
      raise OAuth2::Error.new({error: "A refresh_token is not available"}) unless refresh_token

      params[:grant_type] = "refresh_token"
      params[:refresh_token] = refresh_token
      new_token = @client.get_token(params, access_token_opts, &block)
      new_token.options = options
      if new_token.refresh_token
        # Keep it if there is one
      else
        new_token.refresh_token = refresh_token
      end
      new_token
    end
    # A compatibility alias
    # @note does not modify the receiver, so bang is not the default method
    alias_method :refresh!, :refresh

    # Revokes the token at the authorization server
    #
    # @param [Hash] params additional parameters to be sent during revocation
    # @option params [String, Symbol, nil] :token_type_hint ('access_token' or 'refresh_token') hint about which token to revoke
    # @option params [Symbol] :token_method (:post_with_query_string) overrides OAuth2::Client#options[:token_method]
    #
    # @yield [req] The block is passed the request being made, allowing customization
    # @yieldparam [Faraday::Request] req The request object that can be modified
    #
    # @return [OAuth2::Response] OAuth2::Response instance
    #
    # @api public
    #
    # @raise [OAuth2::Error] if token_type_hint is invalid or the specified token is not available
    #
    # @note If the token passed to the request
    #    is an access token, the server MAY revoke the respective refresh
    #    token as well.
    # @note If the token passed to the request
    #    is a refresh token and the authorization server supports the
    #    revocation of access tokens, then the authorization server SHOULD
    #    also invalidate all access tokens based on the same authorization
    #    grant
    # @note If the server responds with HTTP status code 503, your code must
    #    assume the token still exists and may retry after a reasonable delay.
    #    The server may include a "Retry-After" header in the response to
    #    indicate how long the service is expected to be unavailable to the
    #    requesting client.
    #
    # @see https://datatracker.ietf.org/doc/html/rfc7009
    # @see https://datatracker.ietf.org/doc/html/rfc7009#section-2.1
    def revoke(params = {}, &block)
      token_type_hint_orig = params.delete(:token_type_hint)
      token_type_hint = nil
      revoke_token = case token_type_hint_orig
      when "access_token", :access_token
        token_type_hint = "access_token"
        token
      when "refresh_token", :refresh_token
        token_type_hint = "refresh_token"
        refresh_token
      when nil
        if token
          token_type_hint = "access_token"
          token
        elsif refresh_token
          token_type_hint = "refresh_token"
          refresh_token
        end
      else
        raise OAuth2::Error.new({error: "token_type_hint must be one of [nil, :refresh_token, :access_token], so if you need something else consider using a subclass or entirely custom AccessToken class."})
      end
      raise OAuth2::Error.new({error: "#{token_type_hint || "unknown token type"} is not available for revoking"}) unless revoke_token && !revoke_token.empty?

      @client.revoke_token(revoke_token, token_type_hint, params, &block)
    end
    # A compatibility alias
    # @note does not modify the receiver, so bang is not the default method
    alias_method :revoke!, :revoke

    # Convert AccessToken to a hash which can be used to rebuild itself with AccessToken.from_hash
    #
    # @note Don't return expires_latency because it has already been deducted from expires_at
    #
    # @return [Hash] a hash of AccessToken property values
    def to_hash
      hsh = {
        access_token: token,
        refresh_token: refresh_token,
        expires_at: expires_at,
        mode: options[:mode],
        header_format: options[:header_format],
        param_name: options[:param_name],
      }
      hsh[:token_name] = options[:token_name] if options.key?(:token_name)
      # TODO: Switch when dropping Ruby < 2.5 support
      # params.transform_keys(&:to_sym) # Ruby 2.5 only
      # Old Ruby transform_keys alternative:
      sheesh = @params.each_with_object({}) { |(k, v), memo|
        memo[k.to_sym] = v
      }
      sheesh.merge(hsh)
    end

    # Make a request with the Access Token
    #
    # @param [Symbol] verb the HTTP request method
    # @param [String] path the HTTP URL path of the request
    # @param [Hash] opts the options to make the request with
    # @option opts [Hash] :params additional URL parameters
    # @option opts [Hash, String] :body the request body
    # @option opts [Hash] :headers request headers
    #
    # @yield [req] The block to modify the request
    # @yieldparam [Faraday::Request] req The request object that can be modified
    #
    # @return [OAuth2::Response] the response from the request
    #
    # @see OAuth2::Client#request
    def request(verb, path, opts = {}, &block)
      configure_authentication!(opts, verb)
      @client.request(verb, path, opts, &block)
    end

    # Make a GET request with the Access Token
    #
    # @see AccessToken#request
    def get(path, opts = {}, &block)
      request(:get, path, opts, &block)
    end

    # Make a POST request with the Access Token
    #
    # @see AccessToken#request
    def post(path, opts = {}, &block)
      request(:post, path, opts, &block)
    end

    # Make a PUT request with the Access Token
    #
    # @see AccessToken#request
    def put(path, opts = {}, &block)
      request(:put, path, opts, &block)
    end

    # Make a PATCH request with the Access Token
    #
    # @see AccessToken#request
    def patch(path, opts = {}, &block)
      request(:patch, path, opts, &block)
    end

    # Make a DELETE request with the Access Token
    #
    # @see AccessToken#request
    def delete(path, opts = {}, &block)
      request(:delete, path, opts, &block)
    end

    # Get the headers hash (includes Authorization token)
    def headers
      {"Authorization" => options[:header_format] % token}
    end

  private

    def configure_authentication!(opts, verb)
      mode_opt = options[:mode]
      mode =
        if mode_opt.respond_to?(:call)
          mode_opt.call(verb)
        elsif mode_opt.is_a?(Hash)
          key = verb.to_sym
          # Try symbol key first, then string key; default to :header when missing
          mode_opt[key] || mode_opt[key.to_s] || :header
        else
          mode_opt
        end

      case mode
      when :header
        opts[:headers] ||= {}
        opts[:headers].merge!(headers)
      when :query
        # OAuth 2.1 note: Bearer tokens in the query string are omitted from the spec due to security risks.
        # Prefer the default :header mode whenever possible.
        opts[:params] ||= {}
        opts[:params][options[:param_name]] = token
      when :body
        opts[:body] ||= {}
        if opts[:body].is_a?(Hash)
          opts[:body][options[:param_name]] = token
        else
          opts[:body] += "&#{options[:param_name]}=#{token}"
        end
        # @todo support for multi-part (file uploads)
      else
        raise("invalid :mode option of #{mode}")
      end
    end

    def convert_expires_at(expires_at)
      Time.iso8601(expires_at.to_s).to_i
    rescue ArgumentError
      expires_at.to_i
    end
  end
end
