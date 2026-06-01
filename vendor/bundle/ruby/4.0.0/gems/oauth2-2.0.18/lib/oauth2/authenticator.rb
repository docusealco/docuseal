# frozen_string_literal: true

require "base64"

module OAuth2
  # Builds and applies client authentication to token and revoke requests.
  #
  # Depending on the selected mode, credentials are applied as Basic Auth
  # headers, request body parameters, or only the client_id is sent (TLS).
  class Authenticator
    include FilteredAttributes

    # @return [Symbol, String] Authentication mode (e.g., :basic_auth, :request_body, :tls_client_auth, :private_key_jwt)
    # @return [String, nil] Client identifier
    # @return [String, nil] Client secret (filtered in inspected output)
    attr_reader :mode, :id, :secret
    filtered_attributes :secret

    # Create a new Authenticator
    #
    # @param [String, nil] id Client identifier
    # @param [String, nil] secret Client secret
    # @param [Symbol, String] mode Authentication mode
    def initialize(id, secret, mode)
      @id = id
      @secret = secret
      @mode = mode
    end

    # Apply the request credentials used to authenticate to the Authorization Server
    #
    # Depending on the configuration, this might be as request params or as an
    # Authorization header.
    #
    # User-provided params and header take precedence.
    #
    # @param [Hash] params a Hash of params for the token endpoint
    # @return [Hash] params amended with appropriate authentication details
    def apply(params)
      case mode.to_sym
      when :basic_auth
        apply_basic_auth(params)
      when :request_body
        apply_params_auth(params)
      when :tls_client_auth
        apply_client_id(params)
      when :private_key_jwt
        params
      else
        raise NotImplementedError
      end
    end

    # Encodes a Basic Authorization header value for the provided credentials.
    #
    # @param [String] user The client identifier
    # @param [String] password The client secret
    # @return [String] The value to use for the Authorization header
    def self.encode_basic_auth(user, password)
      "Basic #{Base64.strict_encode64("#{user}:#{password}")}"
    end

  private

    # Adds client_id and client_secret request parameters if they are not
    # already set.
    #
    # @param [Hash] params Request parameters
    # @return [Hash] Updated parameters including client_id and client_secret
    def apply_params_auth(params)
      result = {}
      result["client_id"] = id unless id.nil?
      result["client_secret"] = secret unless secret.nil?
      result.merge(params)
    end

    # When using schemes that don't require the client_secret to be passed (e.g., TLS Client Auth),
    # we don't want to send the secret
    #
    # @param [Hash] params Request parameters
    # @return [Hash] Updated parameters including only client_id
    def apply_client_id(params)
      result = {}
      result["client_id"] = id unless id.nil?
      result.merge(params)
    end

    # Adds an `Authorization` header with Basic Auth credentials if and only if
    # it is not already set in the params.
    #
    # @param [Hash] params Request parameters (may include :headers)
    # @return [Hash] Updated parameters with Authorization header
    def apply_basic_auth(params)
      headers = params.fetch(:headers, {})
      headers = basic_auth_header.merge(headers)
      params.merge(headers: headers)
    end

    # Build the Basic Authorization header.
    #
    # @see https://datatracker.ietf.org/doc/html/rfc2617#section-2
    # @return [Hash] Header hash containing the Authorization entry
    def basic_auth_header
      {"Authorization" => self.class.encode_basic_auth(id, secret)}
    end
  end
end
