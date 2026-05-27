# frozen_string_literal: true

module Aws
  module Sigv4
    # To make it easier to support mixed mode, we have created an asymmetric
    # key derivation mechanism. This module derives
    # asymmetric keys from the current secret for use with
    # Asymmetric signatures.
    # @api private
    module AsymmetricCredentials

      N_MINUS_2 = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551 - 2

      # @return [OpenSSL::PKey::EC, Hash]
      def self.derive_asymmetric_key(access_key_id, secret_access_key)
        check_openssl_support!
        label = 'AWS4-ECDSA-P256-SHA256'
        bit_len = 256
        counter = 0x1
        input_key = "AWS4A#{secret_access_key}"
        d = 0 # d will end up being the private key
        while true do

          kdf_context = access_key_id.unpack('C*') + [counter].pack('C').unpack('C') #1 byte for counter
          input = label.unpack('C*') + [0x00] + kdf_context + [bit_len].pack('L>').unpack('CCCC') # 4 bytes (change endianess)
          k0 = OpenSSL::HMAC.digest("SHA256", input_key, ([0, 0, 0, 0x01] + input).pack('C*'))
          c = be_bytes_to_num( k0.unpack('C*') )
          if c <= N_MINUS_2
            d = c + 1
            break
          elsif counter > 0xFF
            raise 'Counter exceeded 1 byte - unable to get asym creds'
          else
            counter += 1
          end
        end

        # compute the public key
        group = OpenSSL::PKey::EC::Group.new('prime256v1')
        public_key = group.generator.mul(d)

        ec = generate_ec(public_key, d)

        # pk_x and pk_y are not needed for signature, but useful in verification/testing
        pk_b = public_key.to_octet_string(:uncompressed).unpack('C*') # 0x04 byte followed by 2 32-byte integers
        pk_x = be_bytes_to_num(pk_b[1,32])
        pk_y = be_bytes_to_num(pk_b[33,32])
        [ec, {ec: ec, public_key: public_key, pk_x: pk_x, pk_y: pk_y, d: d}]
      end

      private

      # @return [Number] The value of the bytes interpreted as a big-endian
      # unsigned integer.
      def self.be_bytes_to_num(bytes)
        x = 0
        bytes.each { |b| x = (x*256) + b }
        x
      end

      # @return [Array] value of the BigNumber as a big-endian unsigned byte array.
      def self.bn_to_be_bytes(bn)
        bytes = []
        while bn > 0
          bytes << (bn & 0xff)
          bn = bn >> 8
        end
        bytes.reverse
      end

      # Prior to openssl3 we could directly set public and private key on EC
      # However, openssl3 deprecated those methods and we must now construct
      # a der with the keys and load the EC from it.
      def self.generate_ec(public_key, d)
        # format reversed from: OpenSSL::ASN1.decode_all(OpenSSL::PKey::EC.new.to_der)
        asn1 = OpenSSL::ASN1::Sequence([
          OpenSSL::ASN1::Integer(OpenSSL::BN.new(1)),
          OpenSSL::ASN1::OctetString(bn_to_be_bytes(d).pack('C*')),
          OpenSSL::ASN1::ASN1Data.new([OpenSSL::ASN1::ObjectId("prime256v1")], 0, :CONTEXT_SPECIFIC),
          OpenSSL::ASN1::ASN1Data.new(
            [OpenSSL::ASN1::BitString(public_key.to_octet_string(:uncompressed))],
            1, :CONTEXT_SPECIFIC
          )
        ])
        OpenSSL::PKey::EC.new(asn1.to_der)
      end

      def self.check_openssl_support!
        return true unless defined?(JRUBY_VERSION)

        # See: https://github.com/jruby/jruby-openssl/issues/306
        # JRuby-openssl < 0.15 does not support OpenSSL::PKey::EC::Point#mul
        return true if OpenSSL::PKey::EC::Point.instance_methods.include?(:mul)

        raise 'Sigv4a Asymmetric Credential derivation requires jruby-openssl >= 0.15'
      end
    end
  end
end
