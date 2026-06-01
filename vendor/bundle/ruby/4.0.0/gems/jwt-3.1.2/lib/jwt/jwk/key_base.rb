# frozen_string_literal: true

module JWT
  module JWK
    # Base for JWK implementations
    class KeyBase
      def self.inherited(klass)
        super
        ::JWT::JWK.classes << klass
      end

      def initialize(options, params = {})
        options ||= {}

        @parameters = params.transform_keys(&:to_sym) # Uniform interface

        # For backwards compatibility, kid_generator may be specified in the parameters
        options[:kid_generator] ||= @parameters.delete(:kid_generator)

        # Make sure the key has a kid
        kid_generator = options[:kid_generator] || ::JWT.configuration.jwk.kid_generator
        self[:kid] ||= kid_generator.new(self).generate
      end

      def kid
        self[:kid]
      end

      def hash
        self[:kid].hash
      end

      def [](key)
        @parameters[key.to_sym]
      end

      def []=(key, value)
        @parameters[key.to_sym] = value
      end

      def ==(other)
        other.is_a?(::JWT::JWK::KeyBase) && self[:kid] == other[:kid]
      end

      def verify(**kwargs)
        jwa.verify(**kwargs, verification_key: verify_key)
      end

      def sign(**kwargs)
        jwa.sign(**kwargs, signing_key: signing_key)
      end

      alias eql? ==

      def <=>(other)
        return nil unless other.is_a?(::JWT::JWK::KeyBase)

        self[:kid] <=> other[:kid]
      end

      def jwa
        raise JWT::JWKError, 'Could not resolve the JWA, the "alg" parameter is missing' unless self[:alg]

        JWA.resolve(self[:alg]).tap do |jwa|
          raise JWT::JWKError, 'none algorithm usage not supported via JWK' if jwa.is_a?(JWA::None)
        end
      end

      attr_reader :parameters
    end
  end
end
