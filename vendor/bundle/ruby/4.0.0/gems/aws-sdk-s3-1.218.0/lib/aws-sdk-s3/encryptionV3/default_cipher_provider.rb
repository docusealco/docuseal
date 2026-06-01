# frozen_string_literal: true

require 'base64'

module Aws
  module S3
    module EncryptionV3
      # @api private
      class DefaultCipherProvider
        def initialize(options = {})
          @key_provider = options[:key_provider]
          @key_wrap_schema = validate_key_wrap(
            options[:key_wrap_schema],
            @key_provider.encryption_materials.key
          )
          ##= ../specification/s3-encryption/encryption.md#content-encryption
          ##% The S3EC MUST use the encryption algorithm configured during [client](./client.md) initialization.
          @content_encryption_schema = Utils.validate_cek(
            options[:content_encryption_schema]
          )
        end

        attr_reader :key_provider

        # @return [Array<Hash,Cipher>] Creates an returns a new encryption
        #   envelope and encryption cipher.
        def encryption_cipher(options = {})
          validate_options(options)
          data_key = Utils.generate_data_key
          cipher, message_id, commitment_key = Utils.generate_alg_aes_256_gcm_hkdf_sha512_commit_key_cipher(data_key)
          enc_key =
            if @key_provider.encryption_materials.key.is_a? OpenSSL::PKey::RSA
              encode64(
                encrypt_rsa(data_key, @content_encryption_schema)
              )
            else
              encode64(
                encrypt_aes_gcm(data_key, @content_encryption_schema)
              )
            end
          ##= ../specification/s3-encryption/data-format/content-metadata.md#algorithm-suite-and-message-format-version-compatibility
          ##% Objects encrypted with ALG_AES_256_GCM_HKDF_SHA512_COMMIT_KEY MUST use the V3 message format version only.
          envelope = {
            'x-amz-3' => enc_key,
            'x-amz-c' => @content_encryption_schema,
            'x-amz-w' => @key_wrap_schema,
            ##= ../specification/s3-encryption/data-format/content-metadata.md#v3-only
            ##% The Material Description MUST be used for wrapping algorithms `AES/GCM` (`02`) and `RSA-OAEP-SHA1` (`22`).
            'x-amz-m' => materials_description,
            'x-amz-d' => encode64(commitment_key),
            'x-amz-i' => encode64(message_id)
          }

          [envelope, cipher]
        end

        # @return [Cipher] Given an encryption envelope, returns a
        #   decryption cipher.
        def decryption_cipher(envelope, options = {})
          validate_options(options)
          wrapping_key = @key_provider.key_for(envelope['x-amz-m'])

          data_key =
            case envelope['x-amz-w']
            when '02'
              ##= ../specification/s3-encryption/data-format/content-metadata.md#v3-only
              ##% - The wrapping algorithm value "02" MUST be translated to AES/GCM upon retrieval, and vice versa on write.
              if wrapping_key.is_a? OpenSSL::PKey::RSA
                raise ArgumentError, 'Key mismatch - Client is configured' \
                  ' with an RSA key and the x-amz-wrap-alg is AES/GCM.'
              end
              Utils.decrypt_aes_gcm(wrapping_key,
                                    decode64(envelope['x-amz-3']),
                                    @content_encryption_schema)
            when '22'
              ##= ../specification/s3-encryption/data-format/content-metadata.md#v3-only
              ##% - The wrapping algorithm value "22" MUST be translated to RSA-OAEP-SHA1 upon retrieval, and vice versa on write.
              unless wrapping_key.is_a? OpenSSL::PKey::RSA
                raise ArgumentError, 'Key mismatch - Client is configured' \
                  ' with an AES key and the x-amz-wrap-alg is RSA-OAEP-SHA1.'
              end
              key, cek_alg = Utils.decrypt_rsa(wrapping_key, decode64(envelope['x-amz-3']))
              raise Errors::CEKAlgMismatchError unless cek_alg == @content_encryption_schema

              key
            when '12'
              raise ArgumentError, 'Key mismatch - Client is configured' \
                  ' with a user provided key and the x-amz-w is' \
                  ' kms+context.  Please configure the client with the' \
                  ' required kms_key_id'
            else
              raise ArgumentError, 'Unsupported wrapping algorithm: ' \
                    "#{envelope['x-amz-w']}"
            end

          message_id = decode64(envelope['x-amz-i'])
          commitment_key = decode64(envelope['x-amz-d'])

          Utils.derive_alg_aes_256_gcm_hkdf_sha512_commit_key_cipher(data_key, message_id, commitment_key)
        end

        private

        # Validate that the key_wrap_schema
        # is valid, supported and matches the provided key.
        # Returns the string version for the x-amz-key-wrap-alg
        def validate_key_wrap(key_wrap_schema, key)
          if key.is_a? OpenSSL::PKey::RSA
            unless key_wrap_schema == :rsa_oaep_sha1
              raise ArgumentError, ':key_wrap_schema must be set to :rsa_oaep_sha1 for RSA keys.'
            end
          else
            unless key_wrap_schema == :aes_gcm
              raise ArgumentError, ':key_wrap_schema must be set to :aes_gcm for AES keys.'
            end
          end

          case key_wrap_schema
          when :rsa_oaep_sha1 then '22'
          when :aes_gcm then '02'
          when :kms_context
            raise ArgumentError, 'A kms_key_id is required when using :kms_context.'
          else
            raise ArgumentError, "Unsupported key_wrap_schema: #{key_wrap_schema}"
          end
        end

        def encrypt_aes_gcm(data, auth_data)
          Utils.encrypt_aes_gcm(@key_provider.encryption_materials.key, data, auth_data)
        end

        def encrypt_rsa(data, auth_data)
          Utils.encrypt_rsa(@key_provider.encryption_materials.key, data, auth_data)
        end

        def materials_description
          ##= ../specification/s3-encryption/data-format/content-metadata.md#v3-only
          ##% If the mapkey x-amz-m is not present, the default Material Description value MUST be set to an empty map (`{}`).
          @key_provider.encryption_materials.description || {}
        end

        def encode64(str)
          Base64.encode64(str).split("\n") * ''
        end

        def decode64(str)
          Base64.decode64(str)
        end

        def validate_options(options)
          return if options[:kms_encryption_context].nil?

          raise ArgumentError, 'Cannot provide :kms_encryption_context ' \
          'with non KMS client.'
        end
      end
    end
  end
end
