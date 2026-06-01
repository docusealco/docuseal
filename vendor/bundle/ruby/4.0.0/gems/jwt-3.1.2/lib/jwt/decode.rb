# frozen_string_literal: true

require 'json'
require 'jwt/x5c_key_finder'

module JWT
  # The Decode class is responsible for decoding and verifying JWT tokens.
  class Decode
    # Order is very important - first check for string keys, next for symbols
    ALGORITHM_KEYS = ['algorithm',
                      :algorithm,
                      'algorithms',
                      :algorithms].freeze
    # Initializes a new Decode instance.
    #
    # @param jwt [String] the JWT to decode.
    # @param key [String, Array<String>] the key(s) to use for verification.
    # @param verify [Boolean] whether to verify the token's signature.
    # @param options [Hash] additional options for decoding and verification.
    # @param keyfinder [Proc] an optional key finder block to dynamically find the key for verification.
    # @raise [JWT::DecodeError] if decoding or verification fails.
    def initialize(jwt, key, verify, options, &keyfinder)
      raise JWT::DecodeError, 'Nil JSON web token' unless jwt

      @token = EncodedToken.new(jwt)
      @key = key
      @options = options
      @verify = verify
      @keyfinder = keyfinder
    end

    # Decodes the JWT token and verifies its segments if verification is enabled.
    #
    # @return [Array<Hash>] an array containing the decoded payload and header.
    def decode_segments
      validate_segment_count!
      if @verify
        verify_algo
        set_key
        verify_signature
        Claims::DecodeVerifier.verify!(token.unverified_payload, @options)
      end

      [token.unverified_payload, token.header]
    end

    private

    attr_reader :token

    def verify_signature
      return if none_algorithm?

      raise JWT::DecodeError, 'No verification key available' unless @key

      token.verify_signature!(algorithm: allowed_and_valid_algorithms, key: @key)
    end

    def verify_algo
      raise JWT::IncorrectAlgorithm, 'An algorithm must be specified' if allowed_algorithms.empty?
      raise JWT::DecodeError, 'Token header not a JSON object' unless token.header.is_a?(Hash)
      raise JWT::IncorrectAlgorithm, 'Token is missing alg header' unless alg_in_header
      raise JWT::IncorrectAlgorithm, 'Expected a different algorithm' if allowed_and_valid_algorithms.empty?
    end

    def set_key
      @key = find_key(&@keyfinder) if @keyfinder
      if @options[:jwks]
        @key = ::JWT::JWK::KeyFinder.new(
          jwks: @options[:jwks],
          allow_nil_kid: @options[:allow_nil_kid],
          key_fields: @options[:key_fields]
        ).call(token)
      end

      return unless (x5c_options = @options[:x5c])

      @key = X5cKeyFinder.new(x5c_options[:root_certificates], x5c_options[:crls]).from(token.header['x5c'])
    end

    def allowed_and_valid_algorithms
      @allowed_and_valid_algorithms ||= allowed_algorithms.select { |alg| alg.valid_alg?(alg_in_header) }
    end

    def given_algorithms
      alg_key = ALGORITHM_KEYS.find { |key| @options[key] }
      Array(@options[alg_key])
    end

    def allowed_algorithms
      @allowed_algorithms ||= resolve_allowed_algorithms
    end

    def resolve_allowed_algorithms
      given_algorithms.map { |alg| JWA.resolve(alg) }
    end

    def find_key(&keyfinder)
      key = (keyfinder.arity == 2 ? yield(token.header, token.unverified_payload) : yield(token.header))
      # key can be of type [string, nil, OpenSSL::PKey, Array]
      return key if key && !Array(key).empty?

      raise JWT::DecodeError, 'No verification key available'
    end

    def validate_segment_count!
      segment_count = token.jwt.count('.') + 1
      return if segment_count == 3
      return if !@verify && segment_count == 2 # If no verifying required, the signature is not needed
      return if segment_count == 2 && none_algorithm?

      raise JWT::DecodeError, 'Not enough or too many segments'
    end

    def none_algorithm?
      alg_in_header == 'none'
    end

    def alg_in_header
      token.header['alg']
    end
  end
end
