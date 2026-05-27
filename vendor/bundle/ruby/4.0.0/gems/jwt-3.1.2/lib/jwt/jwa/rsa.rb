# frozen_string_literal: true

module JWT
  module JWA
    # Implementation of the RSA family of algorithms
    class Rsa
      include JWT::JWA::SigningAlgorithm

      def initialize(alg)
        @alg = alg
        @digest = alg.sub('RS', 'SHA')
      end

      def sign(data:, signing_key:)
        raise_sign_error!("The given key is a #{signing_key.class}. It has to be an OpenSSL::PKey::RSA instance") unless signing_key.is_a?(OpenSSL::PKey::RSA)
        raise_sign_error!('The key length must be greater than or equal to 2048 bits') if signing_key.n.num_bits < 2048

        signing_key.sign(OpenSSL::Digest.new(digest), data)
      end

      def verify(data:, signature:, verification_key:)
        verification_key.verify(OpenSSL::Digest.new(digest), signature, data)
      rescue OpenSSL::PKey::PKeyError
        raise JWT::VerificationError, 'Signature verification raised'
      end

      register_algorithm(new('RS256'))
      register_algorithm(new('RS384'))
      register_algorithm(new('RS512'))

      private

      attr_reader :digest
    end
  end
end
