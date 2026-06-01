# frozen_string_literal: true

require 'openssl'

module Aws
  module S3
    module EncryptionV3
      # @api private
      module Utils
        class << self
          ##= ../specification/s3-encryption/client.md#encryption-algorithm
          ##% The S3EC MUST validate that the configured encryption algorithm is not legacy.
          def validate_cek(content_encryption_schema)
            ##= ../specification/s3-encryption/data-format/content-metadata.md#algorithm-suite-and-message-format-version-compatibility
            ##% Objects encrypted with ALG_AES_256_GCM_HKDF_SHA512_COMMIT_KEY MUST use the V3 message format version only.
            return '115' if content_encryption_schema.nil?

            case content_encryption_schema
            when :alg_aes_256_gcm_hkdf_sha512_commit_key
              '115'
            else
              ##= ../specification/s3-encryption/encryption.md#alg-aes-256-ctr-iv16-tag16-no-kdf
              ##% Attempts to encrypt using AES-CTR MUST fail.
              ##= ../specification/s3-encryption/encryption.md#alg-aes-256-ctr-hkdf-sha512-commit-key
              ##% Attempts to encrypt using key committing AES-CTR MUST fail.
              ##= ../specification/s3-encryption/client.md#encryption-algorithm
              ##% If the configured encryption algorithm is legacy, then the S3EC MUST throw an exception.
              ##= ../specification/s3-encryption/client.md#key-commitment
              ##% If the configured Encryption Algorithm is incompatible with the key commitment policy, then it MUST throw an exception.
              raise ArgumentError, "Unsupported content_encryption_schema: #{content_encryption_schema}"
            end
          end

          def encrypt_aes_gcm(key, data, auth_data)
            cipher = aes_encryption_cipher(:GCM, key)
            cipher.iv = (iv = cipher.random_iv)
            cipher.auth_data = auth_data

            iv + cipher.update(data) + cipher.final + cipher.auth_tag
          end

          def encrypt_rsa(key, data, auth_data)
            # Plaintext must be KeyLengthInBytes (1 Byte) + DataKey + AuthData
            buf = [data.bytesize] + data.unpack('C*') + auth_data.unpack('C*')
            key.public_encrypt(buf.pack('C*'), OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
          end

          def decrypt_aes_gcm(key, data, auth_data)
            # data is iv (12B) + key + tag (16B)
            buf = data.unpack('C*')
            iv = buf[0, 12].pack('C*') # iv will always be 12 bytes
            tag = buf[-16, 16].pack('C*') # tag is 16 bytes
            enc_key = buf[12, buf.size - (12 + 16)].pack('C*')
            cipher = aes_cipher(:decrypt, :GCM, key, iv)
            cipher.auth_tag = tag
            cipher.auth_data = auth_data
            cipher.update(enc_key) + cipher.final
          end

          # returns the decrypted data + auth_data
          def decrypt_rsa(key, enc_data)
            # Plaintext must be KeyLengthInBytes (1 Byte) + DataKey + AuthData
            buf = key.private_decrypt(enc_data, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING).unpack('C*')
            key_length = buf[0]
            data = buf[1, key_length].pack('C*')
            auth_data = buf[key_length + 1, buf.length - key_length].pack('C*')
            [data, auth_data]
          end

          # @param [String] block_mode "CBC" or "ECB"
          # @param [OpenSSL::PKey::RSA, String, nil] key
          # @param [String, nil] iv The initialization vector
          def aes_encryption_cipher(block_mode, key = nil, iv = nil)
            aes_cipher(:encrypt, block_mode, key, iv)
          end

          # @param [String] block_mode "CBC" or "ECB"
          # @param [OpenSSL::PKey::RSA, String, nil] key
          # @param [String, nil] iv The initialization vector
          def aes_decryption_cipher(block_mode, key = nil, iv = nil)
            aes_cipher(:decrypt, block_mode, key, iv)
          end

          # @param [String] mode "encrypt" or "decrypt"
          # @param [String] block_mode "CBC" or "ECB"
          # @param [OpenSSL::PKey::RSA, String, nil] key
          # @param [String, nil] iv The initialization vector
          def aes_cipher(mode, block_mode, key, iv)
            cipher =
              if key
                OpenSSL::Cipher.new("aes-#{cipher_size(key)}-#{block_mode.downcase}")
              else
                OpenSSL::Cipher.new("aes-256-#{block_mode.downcase}")
              end
            cipher.send(mode) # encrypt or decrypt
            cipher.key = key if key
            cipher.iv = iv if iv
            cipher
          end

          # @param [String] key
          # @return [Integer]
          # @raise ArgumentError
          def cipher_size(key)
            key.bytesize * 8
          end

          # There is only 1 supported algorithm suite at this time
          ENCRYPTION_KEY_INFO = ([0x00, 0x73].pack('C*') + 'DERIVEKEY'.encode('UTF-8')).freeze
          COMMITMENT_KEY_INFO = ([0x00, 0x73].pack('C*') + 'COMMITKEY'.encode('UTF-8')).freeze

          SHA512_DIGEST = OpenSSL::Digest::SHA512.new.freeze
          V3_IV_BYTES = ("\x01" * 12).freeze
          ALGO_ID = [0x00, 0x73].pack('C*').freeze

          def generate_alg_aes_256_gcm_hkdf_sha512_commit_key_cipher(data_key)
            ##= ../specification/s3-encryption/encryption.md#content-encryption
            ##% The client MUST generate an IV or Message ID using the length of the IV or Message ID defined in the algorithm suite.
            message_id = Utils.generate_message_id
            ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
            ##% - The salt MUST be the Message ID with the length defined in the algorithm suite.
            commitment_key = Utils.derive_commitment_key(data_key, message_id)
            cipher = alg_aes_256_gcm_hkdf_sha512_commit_key_cipher(:encrypt, data_key, message_id)

            [
              cipher,
              ##= ../specification/s3-encryption/encryption.md#content-encryption
              ##% The generated IV or Message ID MUST be set or returned from the encryption process such that it can be included in the content metadata.
              message_id,
              ##= ../specification/s3-encryption/encryption.md#alg-aes-256-gcm-hkdf-sha512-commit-key
              ##% The derived key commitment value MUST be set or returned from the encryption process such that it can be included in the content metadata.
              commitment_key
            ]
          end

          def derive_alg_aes_256_gcm_hkdf_sha512_commit_key_cipher(data_key, message_id, stored_commitment_key)
            raise Errors::DecryptionError, 'Data key length does not match algorithm suite' unless data_key.length == 32

            raise Errors::DecryptionError, 'Message id length does not match algorithm suite' unless message_id.length == 28

            unless stored_commitment_key.length == 28
              raise Errors::DecryptionError, 'Commitment key length does not match algorithm suite'
            end

            ##= ../specification/s3-encryption/decryption.md#decrypting-with-commitment
            ##= type=implication
            ##% When using an algorithm suite which supports key commitment,
            ##% the verification of the derived key commitment value MUST be done in constant time.
            unless timing_safe_equal?(
              ##= ../specification/s3-encryption/decryption.md#decrypting-with-commitment
              ##% When using an algorithm suite which supports key commitment,
              ##% the client MUST verify that the [derived key commitment](./key-derivation.md#hkdf-operation) contains the same bytes
              ##% as the stored key commitment retrieved from the stored object's metadata.
              Utils.derive_commitment_key(data_key, message_id),
              stored_commitment_key
            )
              ##= ../specification/s3-encryption/decryption.md#decrypting-with-commitment
              ##% When using an algorithm suite which supports key commitment,
              ##% the client MUST throw an exception when the derived key commitment value and stored key commitment value do not match.
              raise Errors::DecryptionError, 'Commitment key verification failed'
            end

            ##= ../specification/s3-encryption/decryption.md#decrypting-with-commitment
            ##% When using an algorithm suite which supports key commitment,
            ##% the client MUST verify the key commitment values match before deriving the [derived encryption key](./key-derivation.md#hkdf-operation).

            alg_aes_256_gcm_hkdf_sha512_commit_key_cipher(:decrypt, data_key, message_id)
          end

          def alg_aes_256_gcm_hkdf_sha512_commit_key_cipher(mode, data_key, message_id)
            ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
            ##% The client MUST initialize the cipher, or call an AES-GCM encryption API, with the derived encryption key, an IV containing only bytes with the value 0x01,
            ##% and the tag length defined in the Algorithm Suite when encrypting or decrypting with ALG_AES_256_GCM_HKDF_SHA512_COMMIT_KEY.
            cipher = Utils.aes_cipher(
              mode,
              :GCM,
              ##= ../specification/s3-encryption/encryption.md#alg-aes-256-gcm-hkdf-sha512-commit-key
              ##% The client MUST use HKDF to derive the key commitment value and the derived encrypting key as described in [Key Derivation](key-derivation.md).
              Utils.derive_encryption_key(data_key, message_id),
              ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
              ##% When encrypting or decrypting with ALG_AES_256_GCM_HKDF_SHA512_COMMIT_KEY,
              ##% the IV used in the AES-GCM content encryption/decryption MUST consist entirely of bytes with the value 0x01.
              ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
              ##% The IV's total length MUST match the IV length defined by the algorithm suite.
              V3_IV_BYTES
            ) #OpenSSL::Cipher.new("aes-256-gcm")
            ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
            ##% The client MUST set the AAD to the Algorithm Suite ID represented as bytes.
            cipher.auth_data = ALGO_ID # auth_data must be set after key and iv
            cipher
          end

          def generate_data_key
            OpenSSL::Random.random_bytes(32)
          end

          def generate_message_id
            ##= ../specification/s3-encryption/encryption.md#cipher-initialization
            ##= type=exception
            ##= reason=This would be a new runtime error that happens randomly.
            ##% The client SHOULD validate that the generated IV or Message ID is not zeros.

            ##= ../specification/s3-encryption/encryption.md#content-encryption
            ##% The client MUST generate an IV or Message ID using the length of the IV or Message ID defined in the algorithm suite.
            OpenSSL::Random.random_bytes(28)
          end

          def derive_encryption_key(data_key, message_id)
            ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
            ##% - The DEK input pseudorandom key MUST be the output from the extract step.
            hkdf(
              data_key,
              ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
              ##% - The salt MUST be the Message ID with the length defined in the algorithm suite.
              message_id,
              ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
              ##% - The input info MUST be a concatenation of the algorithm suite ID as bytes followed by the string DERIVEKEY as UTF8 encoded bytes.
              ENCRYPTION_KEY_INFO,
              ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
              ##% - The length of the output keying material MUST equal the encryption key length specified by the algorithm suite encryption settings.
              32
            )
          end

          def derive_commitment_key(data_key, message_id)
            ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
            ##% - The CK input pseudorandom key MUST be the output from the extract step.
            hkdf(
              data_key,
              message_id,
              ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
              ##% - The input info MUST be a concatenation of the algorithm suite ID as bytes followed by the string COMMITKEY as UTF8 encoded bytes.
              COMMITMENT_KEY_INFO,
              ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
              ##% - The length of the output keying material MUST equal the commit key length specified by the supported algorithm suites.
              28
            )
          end

          ONE_BYTE = [1].pack('C').freeze
          # assert: the following function is equivalent to `OpenSSL::KDF.hkdf` for all desired_length <= 64
          # see spec: 'produces identical output to native hkdf for random inputs (property-based test)'
          def hkdf_fallback(input_key_material, salt, info, desired_length)
            # Extract from RFC 5869
            # PRK = HMAC-Hash(salt, IKM)
            prk = OpenSSL::HMAC.digest(SHA512_DIGEST, salt, input_key_material)

            # Expand from RFC 5869
            # N = ceil(L/HashLen)
            # T = T(1) | T(2) | T(3) | ... | T(N)
            # OKM = first L octets of T
            #
            # where:
            # T(0) = empty string (zero length)
            # T(1) = HMAC-Hash(PRK, T(0) | info | 0x01)
            # T(2) = HMAC-Hash(PRK, T(1) | info | 0x02)
            # T(3) = HMAC-Hash(PRK, T(2) | info | 0x03)
            #
            # L == desired_length
            # HashLen == 64 (because SHA512_DIGEST is fixed)
            # N = ceil(desired_length/64)
            # The only supported suites have desired_length less than 64
            # This will result in a single iteration of the expand loop.
            # This check verifies that it is safe to do not do a loop
            raise Errors::DecryptionError, "Unsupported length: #{desired_length}" if desired_length > 64

            # assert N == 1
            #
            # For a single iteration of the loop we then get:
            # OKM = first L of T(0) | T(1)
            # ==
            #   (T(0) + T(1))[0, desired_length]
            # == {assert T(0) == ''}
            #   ('' +  HMAC-Hash(PRK, '' + info + 0x01))[0, desired_length]
            # == HMAC-Hash(PRK, info + 0x01)[0, desired_length]
            # == {assert ONE_BYTE == 0x01}
            # HMAC-Hash(PRK, info + ONE_BYTE)[0, desired_length]
            # ==
            OpenSSL::HMAC.digest(SHA512_DIGEST, prk, info + ONE_BYTE)[0, desired_length]
          end

          if defined?(OpenSSL::KDF) && OpenSSL::KDF.respond_to?(:hkdf)
            def hkdf(input_key_material, salt, info, desired_length)
              OpenSSL::KDF.hkdf(
                ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
                ##% - The input keying material MUST be the plaintext data key (PDK) generated by the key provider.
                input_key_material,
                salt: salt,
                info: info,
                ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
                ##% - The length of the input keying material MUST equal the key derivation input length specified by the algorithm suite commit key derivation setting.
                length: desired_length,
                ##= ../specification/s3-encryption/key-derivation.md#hkdf-operation
                ##% - The hash function MUST be specified by the algorithm suite commitment settings.
                hash: SHA512_DIGEST
              )
            end
          else
            # This is done so that we can test hkdf_fallback when we have `OpenSSL::KDF.hkdf`
            alias hkdf hkdf_fallback
          end

          if defined?(OpenSSL) && OpenSSL.respond_to?(:secure_compare)
            def timing_safe_equal?(a, b)
              OpenSSL.secure_compare(a, b)
            end
          else
            def timing_safe_equal?(a, b)
              return false unless a.bytesize == b.bytesize

              l = a.unpack('C*')
              r = 0
              b.each_byte { |byte| r |= byte ^ l.shift }
              r.zero?
            end
          end
        end
      end
    end
  end
end
