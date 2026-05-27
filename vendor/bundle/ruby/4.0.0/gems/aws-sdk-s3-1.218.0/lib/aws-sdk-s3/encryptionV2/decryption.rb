# frozen_string_literal: true

require 'base64'

module Aws
  module S3
    module EncryptionV2
      # @api private
      class Decryption
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-key" MUST be present for V1 format objects.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-iv" MUST be present for V1 format objects.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-matdesc" MUST be present for V1 format objects.
        V1_ENVELOPE_KEYS = %w[
          x-amz-key
          x-amz-iv
          x-amz-matdesc
        ].freeze

        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-key-v2" MUST be present for V2 format objects.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-iv" MUST be present for V2 format objects.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-cek-alg" MUST be present for V2 format objects.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-wrap-alg" MUST be present for V2 format objects.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-matdesc" MUST be present for V2 format objects.
        V2_ENVELOPE_KEYS = %w[
          x-amz-key-v2
          x-amz-iv
          x-amz-cek-alg
          x-amz-wrap-alg
          x-amz-matdesc
        ].freeze

        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##= type=exception
        ##= reason=The implementation treats this as optional, but verifies its value.
        ##% - The mapkey "x-amz-tag-len" MUST be present for V2 format objects.
        V2_OPTIONAL_KEYS = %w[x-amz-tag-len].freeze

        POSSIBLE_ENVELOPE_KEYS = (V1_ENVELOPE_KEYS + V2_ENVELOPE_KEYS + V2_OPTIONAL_KEYS).uniq

        POSSIBLE_WRAPPING_FORMATS = %w[
          AES/GCM
          kms
          kms+context
          RSA-OAEP-SHA1
        ].freeze

        POSSIBLE_ENCRYPTION_FORMATS = %w[
          AES/GCM/NoPadding
          AES/CBC/PKCS5Padding
          AES/CBC/PKCS7Padding
        ].freeze

        AUTH_REQUIRED_CEK_ALGS = %w[AES/GCM/NoPadding].freeze

        class << self
          def decryption_cipher(context)
            if (envelope = get_encryption_envelope(context))
              cipher = context[:encryption][:cipher_provider]
                       .decryption_cipher(
                         envelope,
                         context[:encryption]
                       )
              [cipher, envelope]
            else
              raise Errors::DecryptionError, 'unable to locate encryption envelope'
            end
          end

          def get_decrypter(context, cipher, envelope)
            if body_contains_auth_tag?(envelope)
              authenticated_decrypter(context, cipher, envelope)
            else
              IODecrypter.new(cipher, context.http_response.body)
            end
          end

          def get_encryption_envelope(context)
            if context[:encryption][:envelope_location] == :metadata
              envelope_from_metadata(context) || envelope_from_instr_file(context)
            else
              envelope_from_instr_file(context) || envelope_from_metadata(context)
            end
          end

          def envelope_from_metadata(context)
            possible_envelope = {}
            POSSIBLE_ENVELOPE_KEYS.each do |suffix|
              if (value = context.http_response.headers["x-amz-meta-#{suffix}"])
                possible_envelope[suffix] = value
              end
            end
            extract_envelope(possible_envelope)
          end

          def envelope_from_instr_file(context)
            suffix = context[:encryption][:instruction_file_suffix]
            possible_envelope = Json.load(context.client.get_object(
              bucket: context.params[:bucket],
              key: context.params[:key] + suffix
            ).body.read)
            extract_envelope(possible_envelope)
          rescue S3::Errors::ServiceError, Json::ParseError
            nil
          end

          def extract_envelope(hash)
            return nil unless hash
            ##= ../specification/s3-encryption/data-format/content-metadata.md#determining-s3ec-object-status
            ##% - If the metadata contains "x-amz-iv" and "x-amz-key" then the object MUST be considered as an S3EC-encrypted object using the V1 format.
            return v1_envelope(hash) if hash.key?('x-amz-key')
            ##= ../specification/s3-encryption/data-format/content-metadata.md#determining-s3ec-object-status
            ##% - If the metadata contains "x-amz-iv" and "x-amz-metadata-x-amz-key-v2" then the object MUST be considered as an S3EC-encrypted object using the V2 format.
            return v2_envelope(hash) if hash.key?('x-amz-key-v2')

            return unless hash.keys.any? { |key| key.match(/^x-amz-key-(.+)$/) }

            msg = "unsupported envelope encryption version #{::Regexp.last_match(1)}"
            raise Errors::DecryptionError, msg
          end

          def v1_envelope(envelope)
            envelope
          end

          def v2_envelope(envelope)
            unless POSSIBLE_ENCRYPTION_FORMATS.include? envelope['x-amz-cek-alg']
              alg = envelope['x-amz-cek-alg'].inspect
              msg = "unsupported content encrypting key (cek) format: #{alg}"
              raise Errors::DecryptionError, msg
            end
            unless POSSIBLE_WRAPPING_FORMATS.include? envelope['x-amz-wrap-alg']
              alg = envelope['x-amz-wrap-alg'].inspect
              msg = "unsupported key wrapping algorithm: #{alg}"
              raise Errors::DecryptionError, msg
            end
            unless (missing_keys = V2_ENVELOPE_KEYS - envelope.keys).empty?
              msg = "incomplete v2 encryption envelope:\n"
              msg += "  missing: #{missing_keys.join(',')}\n"
              raise Errors::DecryptionError, msg
            end
            envelope
          end

          def body_contains_auth_tag?(envelope)
            AUTH_REQUIRED_CEK_ALGS.include?(envelope['x-amz-cek-alg'])
          end

          # This method fetches the tag from the end of the object by
          # making a GET Object w/range request. This auth tag is used
          # to initialize the cipher, and the decrypter truncates the
          # auth tag from the body when writing the final bytes.
          def authenticated_decrypter(context, cipher, envelope)
            http_resp = context.http_response
            content_length = http_resp.headers['content-length'].to_i
            auth_tag_length = auth_tag_length(envelope)

            auth_tag = context.client.get_object(
              bucket: context.params[:bucket],
              key: context.params[:key],
              version_id: context.params[:version_id],
              range: "bytes=-#{auth_tag_length}"
            ).body.read

            cipher.auth_tag = auth_tag
            cipher.auth_data = ''

            # The encrypted object contains both the cipher text
            # plus a trailing auth tag.
            IOAuthDecrypter.new(
              io: http_resp.body,
              encrypted_content_length: content_length - auth_tag_length,
              cipher: cipher
            )
          end

          # Determine the auth tag length from the algorithm
          # Validate it against the value provided in the x-amz-tag-len
          # Return the tag length in bytes
          def auth_tag_length(envelope)
            tag_length =
              case envelope['x-amz-cek-alg']
              when 'AES/GCM/NoPadding' then AES_GCM_TAG_LEN_BYTES
              else
                raise ArgumentError, 'Unsupported cek-alg: ' \
                "#{envelope['x-amz-cek-alg']}"
              end
            if (tag_length * 8) != envelope['x-amz-tag-len'].to_i
              raise Errors::DecryptionError, 'x-amz-tag-len does not match expected'
            end

            tag_length
          end
        end
      end
    end
  end
end
