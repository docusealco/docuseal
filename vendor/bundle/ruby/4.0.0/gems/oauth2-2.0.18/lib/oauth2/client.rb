# frozen_string_literal: true

require "faraday"
require "logger"

# :nocov: since coverage tracking only runs on the builds with Faraday v2
# We do run builds on Faraday v0 (and v1!), so this code is actually covered!
# This is the only nocov in the whole project!
if Faraday::Utils.respond_to?(:default_space_encoding)
  # This setting doesn't exist in faraday 0.x
  Faraday::Utils.default_space_encoding = "%20"
end
# :nocov:

module OAuth2
  ConnectionError = Class.new(Faraday::ConnectionFailed)
  TimeoutError = Class.new(Faraday::TimeoutError)

  # The OAuth2::Client class
  class Client # rubocop:disable Metrics/ClassLength
    RESERVED_REQ_KEYS = %w[body headers params redirect_count].freeze
    RESERVED_PARAM_KEYS = (RESERVED_REQ_KEYS + %w[parse snaky snaky_hash_klass token_method]).freeze

    include FilteredAttributes

    attr_reader :id, :secret, :site
    attr_accessor :options
    attr_writer :connection
    filtered_attributes :secret

    # Initializes a new OAuth2::Client instance using the Client ID and Client Secret registered to your application.
    #
    # @param [String] client_id the client_id value
    # @param [String] client_secret the client_secret value
    # @param [Hash] options the options to configure the client
    # @option options [String] :site the OAuth2 provider site host
    # @option options [String] :authorize_url ('/oauth/authorize') absolute or relative URL path to the Authorization endpoint
    # @option options [String] :revoke_url ('/oauth/revoke') absolute or relative URL path to the Revoke endpoint
    # @option options [String] :token_url ('/oauth/token') absolute or relative URL path to the Token endpoint
    # @option options [Symbol] :token_method (:post) HTTP method to use to request token (:get, :post, :post_with_query_string)
    # @option options [Symbol] :auth_scheme (:basic_auth) the authentication scheme (:basic_auth, :request_body, :tls_client_auth, :private_key_jwt)
    # @option options [Hash] :connection_opts ({}) Hash of connection options to pass to initialize Faraday
    # @option options [Boolean] :raise_errors (true) whether to raise an OAuth2::Error on responses with 400+ status codes
    # @option options [Integer] :max_redirects (5) maximum number of redirects to follow
    # @option options [Logger] :logger (::Logger.new($stdout)) Logger instance for HTTP request/response output; requires OAUTH_DEBUG to be true
    # @option options [Class] :access_token_class (AccessToken) class to use for access tokens; you can subclass OAuth2::AccessToken, @version 2.0+
    # @option options [Hash] :ssl SSL options for Faraday
    #
    # @yield [builder] The Faraday connection builder
    def initialize(client_id, client_secret, options = {}, &block)
      opts = options.dup
      @id = client_id
      @secret = client_secret
      @site = opts.delete(:site)
      ssl = opts.delete(:ssl)
      warn("OAuth2::Client#initialize argument `extract_access_token` will be removed in oauth2 v3. Refactor to use `access_token_class`.") if opts[:extract_access_token]
      @options = {
        authorize_url: "oauth/authorize",
        revoke_url: "oauth/revoke",
        token_url: "oauth/token",
        token_method: :post,
        auth_scheme: :basic_auth,
        connection_opts: {},
        connection_build: block,
        max_redirects: 5,
        raise_errors: true,
        logger: ::Logger.new($stdout),
        access_token_class: AccessToken,
      }.merge(opts)
      @options[:connection_opts][:ssl] = ssl if ssl
    end

    # Set the site host
    #
    # @param [String] value the OAuth2 provider site host
    # @return [String] the site host value
    def site=(value)
      @connection = nil
      @site = value
    end

    # The Faraday connection object
    #
    # @return [Faraday::Connection] the initialized Faraday connection
    def connection
      @connection ||=
        Faraday.new(site, options[:connection_opts]) do |builder|
          oauth_debug_logging(builder)
          if options[:connection_build]
            options[:connection_build].call(builder)
          else
            builder.request(:url_encoded)             # form-encode POST params
            builder.adapter(Faraday.default_adapter)  # make requests with Net::HTTP
          end
        end
    end

    # The authorize endpoint URL of the OAuth2 provider
    #
    # @param [Hash] params additional query parameters
    # @return [String] the constructed authorize URL
    def authorize_url(params = {})
      params = (params || {}).merge(redirection_params)
      connection.build_url(options[:authorize_url], params).to_s
    end

    # The token endpoint URL of the OAuth2 provider
    #
    # @param [Hash, nil] params additional query parameters
    # @return [String] the constructed token URL
    def token_url(params = nil)
      connection.build_url(options[:token_url], params).to_s
    end

    # The revoke endpoint URL of the OAuth2 provider
    #
    # @param [Hash, nil] params additional query parameters
    # @return [String] the constructed revoke URL
    def revoke_url(params = nil)
      connection.build_url(options[:revoke_url], params).to_s
    end

    # Makes a request relative to the specified site root.
    #
    # Updated HTTP 1.1 specification (IETF RFC 7231) relaxed the original constraint (IETF RFC 2616),
    #   allowing the use of relative URLs in Location headers.
    #
    # @see https://datatracker.ietf.org/doc/html/rfc7231#section-7.1.2
    #
    # @param [Symbol] verb one of [:get, :post, :put, :delete]
    # @param [String] url URL path of request
    # @param [Hash] req_opts the options to make the request with
    # @option req_opts [Hash] :params additional query parameters for the URL of the request
    # @option req_opts [Hash, String] :body the body of the request
    # @option req_opts [Hash] :headers http request headers
    # @option req_opts [Boolean] :raise_errors whether to raise an OAuth2::Error on 400+ status
    #   code response for this request.  Overrides the client instance setting.
    # @option req_opts [Symbol] :parse @see Response::initialize
    # @option req_opts [Boolean] :snaky (true) @see Response::initialize
    #
    # @yield [req] The block is passed the request being made, allowing customization
    # @yieldparam [Faraday::Request] req The request object that can be modified
    # @see Faraday::Connection#run_request
    #
    # @return [OAuth2::Response] the response from the request
    def request(verb, url, req_opts = {}, &block)
      response = execute_request(verb, url, req_opts, &block)
      status = response.status

      case status
      when 301, 302, 303, 307
        req_opts[:redirect_count] ||= 0
        req_opts[:redirect_count] += 1
        return response if req_opts[:redirect_count] > options[:max_redirects]

        if status == 303
          verb = :get
          req_opts.delete(:body)
        end
        location = response.headers["location"]
        if location
          full_location = response.response.env.url.merge(location)
          request(verb, full_location, req_opts)
        else
          error = Error.new(response)
          raise(error, "Got #{status} status code, but no Location header was present")
        end
      when 200..299, 300..399
        # on non-redirecting 3xx statuses, return the response
        response
      when 400..599
        if req_opts.fetch(:raise_errors, options[:raise_errors])
          error = Error.new(response)
          raise(error)
        end

        response
      else
        error = Error.new(response)
        raise(error, "Unhandled status code value of #{status}")
      end
    end

    # Retrieves an access token from the token endpoint using the specified parameters
    #
    # @param [Hash] params a Hash of params for the token endpoint
    #   * params can include a 'headers' key with a Hash of request headers
    #   * params can include a 'parse' key with the Symbol name of response parsing strategy (default: :automatic)
    #   * params can include a 'snaky' key to control snake_case conversion (default: false)
    # @param [Hash] access_token_opts options that will be passed to the AccessToken initialization
    # @param [Proc] extract_access_token (deprecated) a proc that can extract the access token from the response
    #
    # @yield [opts] The block is passed the options being used to make the request
    # @yieldparam [Hash] opts options being passed to the http library
    #
    # @return [AccessToken, nil] the initialized AccessToken instance, or nil if token extraction fails
    #   and raise_errors is false
    #
    # @note The extract_access_token parameter is deprecated and will be removed in oauth2 v3.
    #   Use access_token_class on initialization instead.
    #
    # @example
    #   client.get_token(
    #     'grant_type' => 'authorization_code',
    #     'code' => 'auth_code_value',
    #     'headers' => {'Authorization' => 'Basic ...'}
    #   )
    def get_token(params, access_token_opts = {}, extract_access_token = nil, &block)
      warn("OAuth2::Client#get_token argument `extract_access_token` will be removed in oauth2 v3. Refactor to use `access_token_class` on #initialize.") if extract_access_token
      extract_access_token ||= options[:extract_access_token]
      req_opts = params_to_req_opts(params)
      response = request(http_method, token_url, req_opts, &block)

      # In v1.4.x, the deprecated extract_access_token option retrieves the token from the response.
      # We preserve this behavior here, but a custom access_token_class that implements #from_hash
      # should be used instead.
      if extract_access_token
        parse_response_legacy(response, access_token_opts, extract_access_token)
      else
        parse_response(response, access_token_opts)
      end
    end

    # Makes a request to revoke a token at the authorization server
    #
    # @param [String] token The token to be revoked
    # @param [String, nil] token_type_hint A hint about the type of the token being revoked (e.g., 'access_token' or 'refresh_token')
    # @param [Hash] params additional parameters for the token revocation
    # @option params [Symbol] :parse (:automatic) parsing strategy for the response
    # @option params [Boolean] :snaky (true) whether to convert response keys to snake_case
    # @option params [Symbol] :token_method (:post_with_query_string) overrides OAuth2::Client#options[:token_method]
    # @option params [Hash] :headers Additional request headers
    #
    # @yield [req] The block is passed the request being made, allowing customization
    # @yieldparam [Faraday::Request] req The request object that can be modified
    #
    # @return [OAuth2::Response] OAuth2::Response instance
    #
    # @api public
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
    def revoke_token(token, token_type_hint = nil, params = {}, &block)
      params[:token_method] ||= :post_with_query_string
      params[:token] = token
      params[:token_type_hint] = token_type_hint if token_type_hint

      req_opts = params_to_req_opts(params)

      request(http_method, revoke_url, req_opts, &block)
    end

    # The HTTP Method of the request
    #
    # @return [Symbol] HTTP verb, one of [:get, :post, :put, :delete]
    def http_method
      http_meth = options[:token_method].to_sym
      return :post if http_meth == :post_with_query_string

      http_meth
    end

    # The Authorization Code strategy
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-15#section-4.1
    def auth_code
      @auth_code ||= OAuth2::Strategy::AuthCode.new(self)
    end

    # The Implicit strategy
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-26#section-4.2
    def implicit
      @implicit ||= OAuth2::Strategy::Implicit.new(self)
    end

    # The Resource Owner Password Credentials strategy
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-15#section-4.3
    def password
      @password ||= OAuth2::Strategy::Password.new(self)
    end

    # The Client Credentials strategy
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-15#section-4.4
    def client_credentials
      @client_credentials ||= OAuth2::Strategy::ClientCredentials.new(self)
    end

    # The Assertion strategy
    #
    # This allows for assertion-based authentication where an identity provider
    # asserts the identity of the user or client application seeking access.
    #
    # @see http://datatracker.ietf.org/doc/html/rfc7521
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-assertions-01#section-4.1
    #
    # @return [OAuth2::Strategy::Assertion] the initialized Assertion strategy
    def assertion
      @assertion ||= OAuth2::Strategy::Assertion.new(self)
    end

    # The redirect_uri parameters, if configured
    #
    # The redirect_uri query parameter is OPTIONAL (though encouraged) when
    # requesting authorization. If it is provided at authorization time it MUST
    # also be provided with the token exchange request.
    #
    # OAuth 2.1 note: Authorization Servers must compare redirect URIs using exact string matching.
    # This client simply forwards the configured redirect_uri; the exact-match validation happens server-side.
    #
    # Providing :redirect_uri to the OAuth2::Client instantiation will take
    # care of managing this.
    #
    # @api semipublic
    #
    # @see https://datatracker.ietf.org/doc/html/rfc6749#section-4.1
    # @see https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3
    # @see https://datatracker.ietf.org/doc/html/rfc6749#section-4.2.1
    # @see https://datatracker.ietf.org/doc/html/rfc6749#section-10.6
    # @see https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1-13
    #
    # @return [Hash] the params to add to a request or URL
    def redirection_params
      if options[:redirect_uri]
        {"redirect_uri" => options[:redirect_uri]}
      else
        {}
      end
    end

  private

    # Processes request parameters and transforms them into request options
    #
    # @param [Hash] params the request parameters to process
    # @option params [Symbol] :parse (:automatic) parsing strategy for the response
    # @option params [Boolean] :snaky (true) whether to convert response keys to snake_case
    # @option params [Class] :snaky_hash_klass (SnakyHash::StringKeyed) class to use for snake_case hash conversion
    # @option params [Symbol] :token_method (:post) HTTP method to use for token request
    # @option params [Hash] :headers Additional HTTP headers for the request
    #
    # @return [Hash] the processed request options
    #
    # @api private
    def params_to_req_opts(params)
      parse, snaky, snaky_hash_klass, token_method, params, headers = parse_snaky_params_headers(params)
      req_opts = {
        raise_errors: options[:raise_errors],
        token_method: token_method || options[:token_method],
        parse: parse,
        snaky: snaky,
        snaky_hash_klass: snaky_hash_klass,
      }
      if req_opts[:token_method] == :post
        # NOTE: If proliferation of request types continues, we should implement a parser solution for Request,
        #       just like we have with Response.
        req_opts[:body] = if headers["Content-Type"] == "application/json"
          params.to_json
        else
          params
        end

        req_opts[:headers] = {"Content-Type" => "application/x-www-form-urlencoded"}
      else
        req_opts[:params] = params
        req_opts[:headers] = {}
      end
      req_opts[:headers].merge!(headers)
      req_opts
    end

    # Processes and transforms parameters for OAuth requests
    #
    # @param [Hash] params the input parameters to process
    # @option params [Symbol] :parse (:automatic) parsing strategy for the response
    # @option params [Boolean] :snaky (true) whether to convert response keys to snake_case
    # @option params [Class] :snaky_hash_klass (SnakyHash::StringKeyed) class to use for snake_case hash conversion
    # @option params [Symbol] :token_method overrides the default token method for this request
    # @option params [Hash] :headers HTTP headers for the request
    #
    # @return [Array<(Symbol, Boolean, Class, Symbol, Hash, Hash)>] Returns an array containing:
    #   - parse strategy (Symbol)
    #   - snaky flag for response key transformation (Boolean)
    #   - hash class for snake_case conversion (Class)
    #   - token method override (Symbol, nil)
    #   - processed parameters (Hash)
    #   - HTTP headers (Hash)
    #
    # @api private
    def parse_snaky_params_headers(params)
      params = params.map do |key, value|
        if RESERVED_PARAM_KEYS.include?(key)
          [key.to_sym, value]
        else
          [key, value]
        end
      end.to_h
      parse = params.key?(:parse) ? params.delete(:parse) : Response::DEFAULT_OPTIONS[:parse]
      snaky = params.key?(:snaky) ? params.delete(:snaky) : Response::DEFAULT_OPTIONS[:snaky]
      snaky_hash_klass = params.key?(:snaky_hash_klass) ? params.delete(:snaky_hash_klass) : Response::DEFAULT_OPTIONS[:snaky_hash_klass]
      token_method = params.delete(:token_method) if params.key?(:token_method)
      params = authenticator.apply(params)
      # authenticator may add :headers, and we separate them from params here
      headers = params.delete(:headers) || {}
      [parse, snaky, snaky_hash_klass, token_method, params, headers]
    end

    # Executes an HTTP request with error handling and response processing
    #
    # @param [Symbol] verb the HTTP method to use (:get, :post, :put, :delete)
    # @param [String] url the URL for the request
    # @param [Hash] opts the request options
    # @option opts [Hash] :body the request body
    # @option opts [Hash] :headers the request headers
    # @option opts [Hash] :params the query parameters to append to the URL
    # @option opts [Symbol, nil] :parse (:automatic) parsing strategy for the response
    # @option opts [Boolean] :snaky (true) whether to convert response keys to snake_case
    #
    # @yield [req] gives access to the request object before sending
    # @yieldparam [Faraday::Request] req the request object that can be modified
    #
    # @return [OAuth2::Response] the response wrapped in an OAuth2::Response object
    #
    # @raise [OAuth2::ConnectionError] when there's a network error
    # @raise [OAuth2::TimeoutError] when the request times out
    #
    # @api private
    def execute_request(verb, url, opts = {})
      url = connection.build_url(url).to_s
      # See: Hash#partition https://bugs.ruby-lang.org/issues/16252
      req_opts, oauth_opts = opts.
        partition { |k, _v| RESERVED_REQ_KEYS.include?(k.to_s) }.
        map { |p| Hash[p] }

      begin
        response = connection.run_request(verb, url, req_opts[:body], req_opts[:headers]) do |req|
          req.params.update(req_opts[:params]) if req_opts[:params]
          yield(req) if block_given?
        end
      rescue Faraday::ConnectionFailed => e
        raise ConnectionError, e
      rescue Faraday::TimeoutError => e
        raise TimeoutError, e
      end

      parse = oauth_opts.key?(:parse) ? oauth_opts.delete(:parse) : Response::DEFAULT_OPTIONS[:parse]
      snaky = oauth_opts.key?(:snaky) ? oauth_opts.delete(:snaky) : Response::DEFAULT_OPTIONS[:snaky]

      Response.new(response, parse: parse, snaky: snaky)
    end

    # Returns the authenticator object
    #
    # @return [Authenticator] the initialized Authenticator
    def authenticator
      Authenticator.new(id, secret, options[:auth_scheme])
    end

    # Parses the OAuth response and builds an access token using legacy extraction method
    #
    # @deprecated Use {#parse_response} instead
    #
    # @param [OAuth2::Response] response the OAuth2::Response from the token endpoint
    # @param [Hash] access_token_opts options to pass to the AccessToken initialization
    # @param [Proc] extract_access_token proc to extract the access token from response
    #
    # @return [AccessToken, nil] the initialized AccessToken if successful, nil if extraction fails
    #   and raise_errors option is false
    #
    # @raise [OAuth2::Error] if response indicates an error and raise_errors option is true
    #
    # @api private
    def parse_response_legacy(response, access_token_opts, extract_access_token)
      access_token = build_access_token_legacy(response, access_token_opts, extract_access_token)

      return access_token if access_token

      if options[:raise_errors]
        error = Error.new(response)
        raise(error)
      end

      nil
    end

    # Parses the OAuth response and builds an access token using the configured access token class
    #
    # @param [OAuth2::Response] response the OAuth2::Response from the token endpoint
    # @param [Hash] access_token_opts options to pass to the AccessToken initialization
    #
    # @return [AccessToken] the initialized AccessToken instance
    #
    # @raise [OAuth2::Error] if the response is empty/invalid and the raise_errors option is true
    #
    # @api private
    def parse_response(response, access_token_opts)
      access_token_class = options[:access_token_class]
      data = response.parsed

      unless data.is_a?(Hash) && !data.empty?
        return unless options[:raise_errors]

        error = Error.new(response)
        raise(error)
      end

      build_access_token(response, access_token_opts, access_token_class)
    end

    # Creates an access token instance from response data using the specified token class
    #
    # @param [OAuth2::Response] response the OAuth2::Response from the token endpoint
    # @param [Hash] access_token_opts additional options to pass to the AccessToken initialization
    # @param [Class] access_token_class the class that should be used to create access token instances
    #
    # @return [AccessToken] an initialized AccessToken instance with response data
    #
    # @note If the access token class responds to response=, the full response object will be set
    #
    # @api private
    def build_access_token(response, access_token_opts, access_token_class)
      access_token_class.from_hash(self, response.parsed.merge(access_token_opts)).tap do |access_token|
        access_token.response = response if access_token.respond_to?(:response=)
      end
    end

    # Builds an access token using a legacy extraction proc
    #
    # @deprecated Use {#build_access_token} instead
    #
    # @param [OAuth2::Response] response the OAuth2::Response from the token endpoint
    # @param [Hash] access_token_opts additional options to pass to the access token extraction
    # @param [Proc] extract_access_token a proc that takes client and token hash as arguments
    #   and returns an access token instance
    #
    # @return [AccessToken, nil] the access token instance if extraction succeeds,
    #   nil if any error occurs during extraction
    #
    # @api private
    def build_access_token_legacy(response, access_token_opts, extract_access_token)
      extract_access_token.call(self, response.parsed.merge(access_token_opts))
    rescue
      # An error will be raised by the called if nil is returned and options[:raise_errors] is truthy, so this rescue is but temporary.
      # Unfortunately, it does hide the real error, but this is deprecated legacy code,
      #   and this was effectively the long-standing pre-existing behavior, so there is little point in changing it.
      nil
    end

    def oauth_debug_logging(builder)
      builder.response(:logger, options[:logger], bodies: true) if OAuth2::OAUTH_DEBUG
    end
  end
end
