# frozen_string_literal: true

require 'base64'

module Aws
  module S3
    module EncryptionV3
      # @api private
      class KmsCipherProvider
        def initialize(options = {})
          @kms_key_id = validate_kms_key(options[:kms_key_id])
          @kms_client = options[:kms_client]
          @key_wrap_schema = validate_key_wrap(
            options[:key_wrap_schema]
          )
          @content_encryption_schema = Utils.validate_cek(
            options[:content_encryption_schema]
          )
        end

        # @return [Array<Hash,Cipher>] Creates and returns a new encryption
        #   envelope and encryption cipher.
        def encryption_cipher(options = {})
          validate_key_for_encryption
          encryption_context = build_encryption_context(@content_encryption_schema, options)
          key_data = Aws::Plugins::UserAgent.metric('S3_CRYPTO_V3') do
            @kms_client.generate_data_key(
              key_id: @kms_key_id,
              encryption_context: encryption_context,
              key_spec: 'AES_256'
            )
          end
          cipher, message_id, commitment_key = Utils.generate_alg_aes_256_gcm_hkdf_sha512_commit_key_cipher(key_data.plaintext)
          ##= ../specification/s3-encryption/data-format/content-metadata.md#algorithm-suite-and-message-format-version-compatibility
          ##% Objects encrypted with ALG_AES_256_GCM_HKDF_SHA512_COMMIT_KEY MUST use the V3 message format version only.
          envelope = {
            'x-amz-3' => encode64(key_data.ciphertext_blob),
            'x-amz-c' => @content_encryption_schema,
            'x-amz-w' => @key_wrap_schema,
            'x-amz-d' => encode64(commitment_key),
            'x-amz-i' => encode64(message_id),
            ##= ../specification/s3-encryption/data-format/content-metadata.md#v3-only
            ##% The Encryption Context value MUST be used for wrapping algorithm `kms+context` or `12`.
            'x-amz-t' => Json.dump(encryption_context)
          }
          [envelope, cipher]
        end

        # @return [Cipher] Given an encryption envelope, returns a
        #   decryption cipher.
        def decryption_cipher(envelope, options = {})
          case envelope['x-amz-w']
          when '12'
            cek_alg = envelope['x-amz-c']
            encryption_context =
              if !envelope['x-amz-t'].nil?
                Json.load(envelope['x-amz-t'])
              else
                ##= ../specification/s3-encryption/data-format/content-metadata.md#v3-only
                ##% If the mapkey x-amz-t is not present, the default Material Description value MUST be set to an empty map (`{}`).
                {}
              end
            ##= ../specification/s3-encryption/data-format/content-metadata.md#v3-only
            ##% - The wrapping algorithm value "12" MUST be translated to kms+context upon retrieval, and vice versa on write.
            raise Errors::CEKAlgMismatchError if cek_alg != encryption_context['aws:x-amz-cek-alg']

            if encryption_context != build_encryption_context(cek_alg, options)
              raise Errors::DecryptionError, 'Value of encryption context from'\
                ' envelope does not match the provided encryption context'
            end
          when '02'
            raise ArgumentError, 'Key mismatch - Client is configured' \
                    ' with a KMS key and the x-amz-wrap-alg is AES/GCM.'
          when '22'
            raise ArgumentError, 'Key mismatch - Client is configured' \
                    ' with a KMS key and the x-amz-wrap-alg is RSA-OAEP-SHA1.'
          when nil
            raise ArgumentError, 'Plaintext passthrough not supported'
          else
            # assert !envelope['x-amz-w'].nil?
            # because of the when above
            raise ArgumentError, 'Unsupported wrapping algorithm: ' \
                "#{envelope['x-amz-w']}"
          end

          any_cmk_mode = options[:kms_allow_decrypt_with_any_cmk]
          decrypt_options = {
            ciphertext_blob: decode64(envelope['x-amz-3']),
            encryption_context: encryption_context
          }
          decrypt_options[:key_id] = @kms_key_id unless any_cmk_mode

          data_key = Aws::Plugins::UserAgent.metric('S3_CRYPTO_V3') do
            @kms_client.decrypt(decrypt_options).plaintext
          end

          message_id = decode64(envelope['x-amz-i'])
          commitment_key = decode64(envelope['x-amz-d'])

          Utils.derive_alg_aes_256_gcm_hkdf_sha512_commit_key_cipher(data_key, message_id, commitment_key)
        end

        private

        def validate_key_wrap(key_wrap_schema)
          case key_wrap_schema
          when :kms_context then '12'
          else
            raise ArgumentError, "Unsupported key_wrap_schema: #{key_wrap_schema}"
          end
        end

        def validate_kms_key(kms_key_id)
          if kms_key_id.nil? || kms_key_id.empty?
            raise ArgumentError, 'KMS CMK ID was not specified. ' \
              'Please specify a CMK ID, ' \
              'or set kms_key_id: :kms_allow_decrypt_with_any_cmk to use ' \
              'any valid CMK from the object.'
          end

          if kms_key_id.is_a?(Symbol) && kms_key_id != :kms_allow_decrypt_with_any_cmk
            raise ArgumentError, 'kms_key_id must be a valid KMS CMK or be ' \
              'set to :kms_allow_decrypt_with_any_cmk'
          end
          kms_key_id
        end

        def build_encryption_context(cek_alg, options = {})
          kms_context = (options[:kms_encryption_context] || {})
                        .transform_keys(&:to_s)
          if kms_context.include? 'aws:x-amz-cek-alg'
            raise ArgumentError, 'Conflict in reserved KMS Encryption Context ' \
              'key aws:x-amz-cek-alg. This value is reserved for the S3 ' \
              'Encryption Client and cannot be set by the user.'
          end
          {
            'aws:x-amz-cek-alg' => cek_alg
          }.merge(kms_context)
        end

        def encode64(str)
          Base64.encode64(str).split("\n") * ''
        end

        def decode64(str)
          Base64.decode64(str)
        end

        def validate_key_for_encryption
          return unless @kms_key_id == :kms_allow_decrypt_with_any_cmk

          raise ArgumentError, 'Unable to encrypt/write objects with '\
            'kms_key_id = :kms_allow_decrypt_with_any_cmk.  Provide ' \
            'a valid kms_key_id on client construction.'
        end
      end
    end
  end
end
