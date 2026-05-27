# frozen_string_literal: true

module JWT
  # Represents an encoded JWT token
  #
  # Processing an encoded and signed token:
  #
  #   token = JWT::Token.new(payload: {pay: 'load'})
  #   token.sign!(algorithm: 'HS256', key: 'secret')
  #
  #   encoded_token = JWT::EncodedToken.new(token.jwt)
  #   encoded_token.verify_signature!(algorithm: 'HS256', key: 'secret')
  #   encoded_token.payload # => {'pay' => 'load'}
  class EncodedToken
    # @private
    # Allow access to the unverified payload for claim verification.
    class ClaimsContext
      extend Forwardable

      def_delegators :@token, :header, :unverified_payload

      def initialize(token)
        @token = token
      end

      def payload
        unverified_payload
      end
    end

    DEFAULT_CLAIMS = [:exp].freeze

    private_constant(:DEFAULT_CLAIMS)

    # Returns the original token provided to the class.
    # @return [String] The JWT token.
    attr_reader :jwt

    # Initializes a new EncodedToken instance.
    #
    # @param jwt [String] the encoded JWT token.
    # @raise [ArgumentError] if the provided JWT is not a String.
    def initialize(jwt)
      raise ArgumentError, 'Provided JWT must be a String' unless jwt.is_a?(String)

      @jwt = jwt
      @signature_verified = false
      @claims_verified    = false

      @encoded_header, @encoded_payload, @encoded_signature = jwt.split('.')
    end

    # Returns the decoded signature of the JWT token.
    #
    # @return [String] the decoded signature.
    def signature
      @signature ||= ::JWT::Base64.url_decode(encoded_signature || '')
    end

    # Returns the encoded signature of the JWT token.
    #
    # @return [String] the encoded signature.
    attr_reader :encoded_signature

    # Returns the decoded header of the JWT token.
    #
    # @return [Hash] the header.
    def header
      @header ||= parse_and_decode(@encoded_header)
    end

    # Returns the encoded header of the JWT token.
    #
    # @return [String] the encoded header.
    attr_reader :encoded_header

    # Returns the payload of the JWT token. Access requires the signature and claims to have been verified.
    #
    # @return [Hash] the payload.
    # @raise [JWT::DecodeError] if the signature has not been verified.
    def payload
      raise JWT::DecodeError, 'Verify the token signature before accessing the payload' unless @signature_verified
      raise JWT::DecodeError, 'Verify the token claims before accessing the payload' unless @claims_verified

      decoded_payload
    end

    # Returns the payload of the JWT token without requiring the signature to have been verified.
    # @return [Hash] the payload.
    def unverified_payload
      decoded_payload
    end

    # Sets or returns the encoded payload of the JWT token.
    #
    # @return [String] the encoded payload.
    attr_accessor :encoded_payload

    # Returns the signing input of the JWT token.
    #
    # @return [String] the signing input.
    def signing_input
      [encoded_header, encoded_payload].join('.')
    end

    # Verifies the token signature and claims.
    # By default it verifies the 'exp' claim.
    #
    # @example
    #  encoded_token.verify!(signature: { algorithm: 'HS256', key: 'secret' }, claims: [:exp])
    #
    # @param signature [Hash] the parameters for signature verification (see {#verify_signature!}).
    # @param claims [Array<Symbol>, Hash] the claims to verify (see {#verify_claims!}).
    # @return [nil]
    # @raise [JWT::DecodeError] if the signature or claim verification fails.
    def verify!(signature:, claims: nil)
      verify_signature!(**signature)
      claims.is_a?(Array) ? verify_claims!(*claims) : verify_claims!(claims)
      nil
    end

    # Verifies the token signature and claims.
    # By default it verifies the 'exp' claim.

    # @param signature [Hash] the parameters for signature verification (see {#verify_signature!}).
    # @param claims [Array<Symbol>, Hash] the claims to verify (see {#verify_claims!}).
    # @return [Boolean] true if the signature and claims are valid, false otherwise.
    def valid?(signature:, claims: nil)
      valid_signature?(**signature) &&
        (claims.is_a?(Array) ? valid_claims?(*claims) : valid_claims?(claims))
    end

    # Verifies the signature of the JWT token.
    #
    # @param algorithm [String, Array<String>, Object, Array<Object>] the algorithm(s) to use for verification.
    # @param key [String, Array<String>] the key(s) to use for verification.
    # @param key_finder [#call] an object responding to `call` to find the key for verification.
    # @return [nil]
    # @raise [JWT::VerificationError] if the signature verification fails.
    # @raise [ArgumentError] if neither key nor key_finder is provided, or if both are provided.
    def verify_signature!(algorithm:, key: nil, key_finder: nil)
      return if valid_signature?(algorithm: algorithm, key: key, key_finder: key_finder)

      raise JWT::VerificationError, 'Signature verification failed'
    end

    # Checks if the signature of the JWT token is valid.
    #
    # @param algorithm [String, Array<String>, Object, Array<Object>] the algorithm(s) to use for verification.
    # @param key [String, Array<String>, JWT::JWK::KeyBase, Array<JWT::JWK::KeyBase>] the key(s) to use for verification.
    # @param key_finder [#call] an object responding to `call` to find the key for verification.
    # @return [Boolean] true if the signature is valid, false otherwise.
    def valid_signature?(algorithm: nil, key: nil, key_finder: nil)
      raise ArgumentError, 'Provide either key or key_finder, not both or neither' if key.nil? == key_finder.nil?

      keys      = Array(key || key_finder.call(self))
      verifiers = JWA.create_verifiers(algorithms: algorithm, keys: keys, preferred_algorithm: header['alg'])

      raise JWT::VerificationError, 'No algorithm provided' if verifiers.empty?

      valid = verifiers.any? do |jwa|
        jwa.verify(data: signing_input, signature: signature)
      end
      valid.tap { |verified| @signature_verified = verified }
    end

    # Verifies the claims of the token.
    # @param options [Array<Symbol>, Hash] the claims to verify. By default, it checks the 'exp' claim.
    # @raise [JWT::DecodeError] if the claims are invalid.
    def verify_claims!(*options)
      Claims::Verifier.verify!(ClaimsContext.new(self), *claims_options(options)).tap do
        @claims_verified = true
      end
    rescue StandardError
      @claims_verified = false
      raise
    end

    # Returns the errors of the claims of the token.
    # @param options [Array<Symbol>, Hash] the claims to verify. By default, it checks the 'exp' claim.
    # @return [Array<Symbol>] the errors of the claims.
    def claim_errors(*options)
      Claims::Verifier.errors(ClaimsContext.new(self), *claims_options(options))
    end

    # Returns whether the claims of the token are valid.
    # @param options [Array<Symbol>, Hash] the claims to verify. By default, it checks the 'exp' claim.
    # @return [Boolean] whether the claims are valid.
    def valid_claims?(*options)
      claim_errors(*claims_options(options)).empty?.tap { |verified| @claims_verified = verified }
    end

    alias to_s jwt

    private

    def claims_options(options)
      return DEFAULT_CLAIMS if options.first.nil?

      options
    end

    def decode_payload
      raise JWT::DecodeError, 'Encoded payload is empty' if encoded_payload == ''

      if unencoded_payload?
        verify_claims!(crit: ['b64'])
        return parse_unencoded(encoded_payload)
      end

      parse_and_decode(encoded_payload)
    end

    def unencoded_payload?
      header['b64'] == false
    end

    def parse_and_decode(segment)
      parse(::JWT::Base64.url_decode(segment || ''))
    end

    def parse_unencoded(segment)
      parse(segment)
    end

    def parse(segment)
      JWT::JSON.parse(segment)
    rescue ::JSON::ParserError
      raise JWT::DecodeError, 'Invalid segment encoding'
    end

    def decoded_payload
      @decoded_payload ||= decode_payload
    end
  end
end
