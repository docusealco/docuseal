# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.
# Copyright, 2022, by Philip Arndt.

require 'base64'
require 'json'
require 'openssl'
require 'securerandom'

require 'rack/utils'

module Rack
  module Session
    class Encryptor
      class Error < StandardError
      end

      class InvalidSignature < Error
      end

      class InvalidMessage < Error
      end

      module Serializable
        private

        # Returns a serialized payload of the message. If a :pad_size is supplied,
        # the message will be padded. The first 2 bytes of the returned string will
        # indicating the amount of padding.
        def serialize_payload(message)
          serialized_data = serializer.dump(message)

          return "#{[0].pack('v')}#{serialized_data.force_encoding(Encoding::BINARY)}" if @options[:pad_size].nil?

          padding_bytes = @options[:pad_size] - (2 + serialized_data.size) % @options[:pad_size]
          padding_data = SecureRandom.random_bytes(padding_bytes)

          "#{[padding_bytes].pack('v')}#{padding_data}#{serialized_data.force_encoding(Encoding::BINARY)}"
        end

        # Return the deserialized message. The first 2 bytes will be read as the
        # amount of padding.
        def deserialized_message(data)
          # Read the first 2 bytes as the padding_bytes size
          padding_bytes, = data.unpack('v')

          # Slice out the serialized_data and deserialize it
          serialized_data = data.slice(2 + padding_bytes, data.bytesize)
          serializer.load serialized_data
        end

        def serializer
          @serializer ||= @options[:serialize_json] ? JSON : Marshal
        end
      end

      class V1
        include Serializable

        # The secret String must be at least 64 bytes in size. The first 32 bytes
        # will be used for the encryption cipher key. The remainder will be used
        # for an HMAC key.
        #
        # Options may include:
        # * :serialize_json
        #     Use JSON for message serialization instead of Marshal. This can be
        #     viewed as a security enhancement.
        # * :pad_size
        #     Pad encrypted message data, to a multiple of this many bytes
        #     (default: 32). This can be between 2-4096 bytes, or +nil+ to disable
        #     padding.
        # * :purpose
        #     Limit messages to a specific purpose. This can be viewed as a
        #     security enhancement to prevent message reuse from different contexts
        #     if keys are reused.
        #
        # Cryptography and Output Format:
        #
        #   urlsafe_encode64(version + random_data + IV + encrypted data + HMAC)
        #
        #  Where:
        #  * version - 1 byte with value 0x01
        #  * random_data - 32 bytes used for generating the per-message secret
        #  * IV - 16 bytes random initialization vector
        #  * HMAC - 32 bytes HMAC-SHA-256 of all preceding data, plus the purpose
        #    value
        def initialize(secret, opts = {})
          raise ArgumentError, 'secret must be a String' unless secret.is_a?(String)
          raise ArgumentError, "invalid secret: #{secret.bytesize}, must be >=64" unless secret.bytesize >= 64

          case opts[:pad_size]
          when nil
          # padding is disabled
          when Integer
            raise ArgumentError, "invalid pad_size: #{opts[:pad_size]}" unless (2..4096).include? opts[:pad_size]
          else
            raise ArgumentError, "invalid pad_size: #{opts[:pad_size]}; must be Integer or nil"
          end

          @options = {
            serialize_json: false, pad_size: 32, purpose: nil
          }.update(opts)

          @hmac_secret = secret.dup.force_encoding(Encoding::BINARY)
          @cipher_secret = @hmac_secret.slice!(0, 32)

          @hmac_secret.freeze
          @cipher_secret.freeze
        end

        def decrypt(base64_data)
          data = Base64.urlsafe_decode64(base64_data)

          signature = data.slice!(-32..-1)
          verify_authenticity!(data, signature)

          version = data.slice!(0, 1)
          raise InvalidMessage, 'wrong version' unless version == "\1"

          message_secret = data.slice!(0, 32)
          cipher_iv = data.slice!(0, 16)

          cipher = new_cipher
          cipher.decrypt

          set_cipher_key(cipher, cipher_secret_from_message_secret(message_secret))

          cipher.iv = cipher_iv
          data = cipher.update(data) << cipher.final

          deserialized_message data
        rescue ArgumentError
          raise InvalidSignature, 'Message invalid'
        end

        def encrypt(message)
          version = "\1"

          serialized_payload = serialize_payload(message)
          message_secret, cipher_secret = new_message_and_cipher_secret

          cipher = new_cipher
          cipher.encrypt

          set_cipher_key(cipher, cipher_secret)

          cipher_iv = cipher.random_iv

          encrypted_data = cipher.update(serialized_payload) << cipher.final

          data = String.new
          data << version
          data << message_secret
          data << cipher_iv
          data << encrypted_data
          data << compute_signature(data)

          Base64.urlsafe_encode64(data)
        end

        private

        def new_cipher
          OpenSSL::Cipher.new('aes-256-ctr')
        end

        def new_message_and_cipher_secret
          message_secret = SecureRandom.random_bytes(32)

          [message_secret, cipher_secret_from_message_secret(message_secret)]
        end

        def cipher_secret_from_message_secret(message_secret)
          OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), @cipher_secret, message_secret)
        end

        def set_cipher_key(cipher, key)
          cipher.key = key
        end

        def compute_signature(data)
          signing_data = data
          signing_data += @options[:purpose] if @options[:purpose]

          OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), @hmac_secret, signing_data)
        end

        def verify_authenticity!(data, signature)
          raise InvalidMessage, 'Message is invalid' if data.nil? || signature.nil?

          unless Rack::Utils.secure_compare(signature, compute_signature(data))
            raise InvalidSignature, 'HMAC is invalid'
          end
        end
      end

      class V2
        include Serializable

        # The secret String must be at least 32 bytes in size.
        #
        # Options may include:
        # * :pad_size
        #     Pad encrypted message data, to a multiple of this many bytes
        #     (default: 32). This can be between 2-4096 bytes, or +nil+ to disable
        #     padding.
        # * :purpose
        #     Limit messages to a specific purpose. This can be viewed as a
        #     security enhancement to prevent message reuse from different contexts
        #     if keys are reused.
        #
        # Cryptography and Output Format:
        #
        #   strict_encode64(version + salt + IV + authentication tag + ciphertext)
        #
        #  Where:
        #  * version - 1 byte with value 0x02
        #  * salt - 32 bytes used for generating the per-message secret
        #  * IV - 12 bytes random initialization vector
        #  * authentication tag - 16 bytes authentication tag generated by the GCM mode, covering version and salt
        #
        # Considerations about V2:
        #
        # 1) It uses non URL-safe Base64 encoding as it's faster than its
        #    URL-safe counterpart - as of Ruby 3.2, Base64.urlsafe_encode64 is
        #    roughly equivalent to
        #
        #    Base64.strict_encode64(data).tr("-_", "+/")
        #
        #    - and cookie values don't need to be URL-safe.
        def initialize(secret, opts = {})
          raise ArgumentError, 'secret must be a String' unless secret.is_a?(String)

          unless secret.bytesize >= 32
            raise ArgumentError, "invalid secret: it's #{secret.bytesize}-byte long, must be >=32"
          end

          case opts[:pad_size]
          when nil
          # padding is disabled
          when Integer
            raise ArgumentError, "invalid pad_size: #{opts[:pad_size]}" unless (2..4096).include? opts[:pad_size]
          else
            raise ArgumentError, "invalid pad_size: #{opts[:pad_size]}; must be Integer or nil"
          end

          @options = {
            serialize_json: false, pad_size: 32, purpose: nil
          }.update(opts)

          @cipher_secret = secret.dup.force_encoding(Encoding::BINARY).slice!(0, 32)
          @cipher_secret.freeze
        end

        def decrypt(base64_data)
          data = Base64.strict_decode64(base64_data)
          if data.bytesize <= 61 # version + salt + iv + auth_tag = 61 byte (and we also need some ciphertext :)
            raise InvalidMessage, 'invalid message'
          end

          version = data[0]
          raise InvalidMessage, 'invalid message' unless version == "\2"

          ciphertext = data.slice!(61..-1)
          auth_tag = data.slice!(45, 16)
          cipher_iv = data.slice!(33, 12)

          cipher = new_cipher
          cipher.decrypt
          salt = data.slice(1, 32)
          set_cipher_key(cipher, message_secret_from_salt(salt))
          cipher.iv = cipher_iv
          cipher.auth_tag = auth_tag
          cipher.auth_data = (purpose = @options[:purpose]) ? data + purpose : data

          plaintext = cipher.update(ciphertext) << cipher.final

          deserialized_message plaintext
        rescue ArgumentError, OpenSSL::Cipher::CipherError
          raise InvalidSignature, 'invalid message'
        end

        def encrypt(message)
          version = "\2"

          serialized_payload = serialize_payload(message)

          cipher = new_cipher
          cipher.encrypt
          salt, message_secret = new_salt_and_message_secret
          set_cipher_key(cipher, message_secret)
          cipher.iv_len = 12
          cipher_iv = cipher.random_iv

          data = String.new
          data << version
          data << salt

          cipher.auth_data = (purpose = @options[:purpose]) ? data + purpose : data
          encrypted_data = cipher.update(serialized_payload) << cipher.final

          data << cipher_iv
          data << auth_tag_from(cipher)
          data << encrypted_data

          Base64.strict_encode64(data)
        end

        private

        def new_cipher
          OpenSSL::Cipher.new('aes-256-gcm')
        end

        def new_salt_and_message_secret
          salt = SecureRandom.random_bytes(32)

          [salt, message_secret_from_salt(salt)]
        end

        def message_secret_from_salt(salt)
          OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), @cipher_secret, salt)
        end

        def set_cipher_key(cipher, key)
          cipher.key = key
        end

        if RUBY_ENGINE == 'jruby'
          # JRuby's OpenSSL implementation doesn't currently support passing
          # an argument to #auth_tag. Here we work around that.
          def auth_tag_from(cipher)
            tag = cipher.auth_tag
            raise Error, 'the auth tag must be 16 bytes long' if tag.bytesize != 16

            tag
          end
        else
          def auth_tag_from(cipher)
            cipher.auth_tag(16)
          end
        end
      end

      def initialize(secret, opts = {})
        opts = opts.dup

        @mode = opts.delete(:mode)&.to_sym || :guess_version
        case @mode
        when :v1
          @v1 = V1.new(secret, opts)
        when :v2
          @v2 = V2.new(secret, opts)
        else
          @v1 = V1.new(secret, opts)
          @v2 = V2.new(secret, opts)
        end
      end

      def decrypt(base64_data)
        decryptor =
          case @mode
          when :v2
            v2
          when :v1
            v1
          else
            guess_decryptor(base64_data)
          end

        decryptor.decrypt(base64_data)
      end

      def encrypt(message)
        encryptor =
          case @mode
          when :v1
            v1
          else
            v2
          end

        encryptor.encrypt(message)
      end

      private

      attr_reader :v1, :v2

      def guess_decryptor(base64_data)
        raise InvalidMessage, 'invalid message' if base64_data.nil? || base64_data.bytesize < 4

        first_encoded_4_bytes = base64_data.slice(0, 4)
        # Transform the 4 bytes into non-URL-safe base64-encoded data. Nothing
        # happens if the data is already non-URL-safe base64.
        first_encoded_4_bytes.tr!('-_', '+/')
        first_decoded_3_bytes = Base64.strict_decode64(first_encoded_4_bytes)

        version = first_decoded_3_bytes[0]
        case version
        when "\2"
          v2
        when "\1"
          v1
        else
          raise InvalidMessage, 'invalid message'
        end
      rescue ArgumentError
        raise InvalidMessage, 'invalid message'
      end
    end
  end
end
