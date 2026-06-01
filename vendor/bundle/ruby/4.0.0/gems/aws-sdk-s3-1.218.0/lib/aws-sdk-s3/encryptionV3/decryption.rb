# frozen_string_literal: true

require 'base64'

module Aws
  module S3
    module EncryptionV3
      # @api private
      class Decryption
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##= type=implication
        ##% The "x-amz-" prefix denotes that the metadata is owned by an Amazon product and MUST be prepended to all S3EC metadata mapkeys.

        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-3" MUST be present for V3 format objects.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-w" MUST be present for V3 format objects.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##= type=implication
        ##% - This mapkey ("x-amz-3") SHOULD be represented by a constant named "ENCRYPTED_DATA_KEY_V3" or similar in the implementation code.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##= type=implication
        ##% - This mapkey ("x-amz-w") SHOULD be represented by a constant named "ENCRYPTED_DATA_KEY_ALGORITHM_V3" or similar in the implementation code.
        ENVELOP_KEY = %w[
          x-amz-3
          x-amz-w
        ].freeze

        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-m" SHOULD be present for V3 format objects that use Raw Keyring Material Description.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-t" SHOULD be present for V3 format objects that use KMS Encryption Context.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##= type=implication
        ##% - This mapkey ("x-amz-m") SHOULD be represented by a constant named "MAT_DESC_V3" or similar in the implementation code.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##= type=implication
        ##% - This mapkey ("x-amz-t") SHOULD be represented by a constant named "ENCRYPTION_CONTEXT_V3" or similar in the implementation code.
        OPTIONAL_ENVELOP_KEY = %w[
          x-amz-m
          x-amz-t
        ].freeze

        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-c" MUST be present for V3 format objects.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-d" MUST be present for V3 format objects.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##% - The mapkey "x-amz-i" MUST be present for V3 format objects.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##= type=implication
        ##% - This mapkey ("x-amz-c") SHOULD be represented by a constant named "CONTENT_CIPHER_V3" or similar in the implementation code.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##= type=implication
        ##% - This mapkey ("x-amz-d") SHOULD be represented by a constant named "KEY_COMMITMENT_V3" or similar in the implementation code.
        ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
        ##= type=implication
        ##% - This mapkey ("x-amz-i") SHOULD be represented by a constant named "MESSAGE_ID_V3" or similar in the implementation code.
        METADATA_KEY = %w[
          x-amz-c
          x-amz-d
          x-amz-i
        ].freeze

        # Reference V2's envelope keys rather than duplicating them
        LEGACY_POSSIBLE_ENVELOPE_KEYS = Aws::S3::EncryptionV2::Decryption::POSSIBLE_ENVELOPE_KEYS

        POSSIBLE_ENVELOPE_KEYS = (ENVELOP_KEY + METADATA_KEY + OPTIONAL_ENVELOP_KEY + LEGACY_POSSIBLE_ENVELOPE_KEYS).uniq
        REQUIRED_ENVELOPE_KEYS = (ENVELOP_KEY + METADATA_KEY).uniq

        POSSIBLE_WRAPPING_FORMATS = %w[
          01
          02
          11
          12
          21
          22
        ].freeze

        POSSIBLE_ENCRYPTION_FORMATS = %w[
          115
        ].freeze

        class << self
          def v3?(context)
            context.http_response.headers.key?('x-amz-meta-x-amz-i')
          end

          def decryption_cipher(context)
            if (envelope = get_encryption_envelope(context))
              cipher = context[:encryption][:v3_cipher_provider]
                       .decryption_cipher(
                         envelope,
                         context[:encryption]
                       )
              [cipher, envelope]
            else
              raise Errors::DecryptionError, 'unable to locate encryption envelope'
            end
          end

          # This method fetches the tag from the end of the object by
          # making a GET Object w/range request. This auth tag is used
          # to initialize the cipher, and the decrypter truncates the
          # auth tag from the body when writing the final bytes.
          def get_decrypter(context, cipher, _envelope)
            http_resp = context.http_response
            content_length = http_resp.headers['content-length'].to_i

            # The encrypted object contains both the cipher text
            # plus a trailing auth tag.
            # The trailing auth tag will be accumulated and added to the cipher.auth_tag.
            IOAuthDecrypter.new(
              io: http_resp.body,
              encrypted_content_length: content_length - AES_GCM_TAG_LEN_BYTES,
              cipher: cipher
            )
          end

          def get_encryption_envelope(context)
            # Get initial envelope data from :envelope_location
            envelope =
              if context[:encryption][:envelope_location] == :metadata
                envelope_from_metadata(context)
              else
                envelope_from_instr_file(context)
              end

            # If empty or incomplete, get/merge data from secondary source
            ##= ../specification/s3-encryption/data-format/content-metadata.md#determining-s3ec-object-status
            ##% If the object matches none of the V1/V2/V3 formats, the S3EC MUST attempt to get the instruction file.
            if envelope.nil? || envelope.empty? || !complete_envelop?(envelope)
              secondary =
                if context[:encryption][:envelope_location] == :metadata
                  envelope_from_instr_file(context)
                else
                  envelope_from_metadata(context)
                end
                # If we attempted to read a non-existent instruction file,
                # then envelope would be nil,
                # but we may find the information we need in the metadata.
                if envelope && secondary
                  envelope.merge!(secondary)
                elsif secondary
                  envelope = secondary
                end
            end

            ##= ../specification/s3-encryption/data-format/metadata-strategy.md#object-metadata
            ##% If the S3EC does not support decoding the S3 Server's "double encoding" then it MUST return the content metadata untouched.
            v3_envelope?(envelope)
          end

          def complete_envelop?(possible_envelope)
            # V3 envelops always store some information in metadata
            # If we look at the metadata, we may still need to check the instruction file
            # Similarly, if we start checking the instruction file,
            # we sill need to get the message id and commitment key from the metadata
            envelop_count = ENVELOP_KEY.count { |key| possible_envelope.key?(key) }
            metadata_count = METADATA_KEY.count { |key| possible_envelope.key?(key) }

            # If we have all keys, we are done
            (envelop_count == ENVELOP_KEY.size && metadata_count == METADATA_KEY.size) ||
              # If we have 0 keys, then this is done too.
              # Because it means we are not a v3 committing message.
              (envelop_count.zero? && metadata_count.zero?)
          end

          def envelope_from_metadata(context)
            POSSIBLE_ENVELOPE_KEYS.filter_map do |suffix|
              ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
              ##= type=exception
              ##= reason=Ruby is reading the headers directly
              ##% The "x-amz-meta-" prefix is automatically added by the S3 server and MUST NOT be included in implementation code.
              if (value = context.http_response.headers["x-amz-meta-#{suffix}"])
                ##= ../specification/s3-encryption/data-format/metadata-strategy.md#object-metadata
                ##= type=exception
                ##= reason=This has never been supported in Ruby
                ##% The S3EC SHOULD support decoding the S3 Server's "double encoding".

                ##= ../specification/s3-encryption/data-format/metadata-strategy.md#object-metadata
                ##% If the S3EC does not support decoding the S3 Server's "double encoding" then it MUST return the content metadata untouched.
                [suffix, value]
              end
            end.to_h
          end

          def envelope_from_instr_file(context)
            suffix = context[:encryption][:instruction_file_suffix]
            possible_envelope = Json.load(context.client.get_object(
              bucket: context.params[:bucket],
              key: context.params[:key] + suffix
            ).body.read)
            unless (keys = possible_envelope.keys & METADATA_KEY).empty?
              msg = "unsupported metadata key found in instruction file: #{keys.join(', ')}"
              raise Errors::DecryptionError, msg
            end
            possible_envelope
          rescue S3::Errors::ServiceError, Json::ParseError
            nil
          end

          def v3_envelope?(possible_envelope)
            unless (keys = possible_envelope.keys & LEGACY_POSSIBLE_ENVELOPE_KEYS).empty?
              ##= ../specification/s3-encryption/data-format/content-metadata.md#determining-s3ec-object-status
              ##% If there are multiple mapkeys which are meant to be exclusive, such as "x-amz-key", "x-amz-key-v2", and "x-amz-3" then the S3EC SHOULD throw an exception.
              msg = "legacy metadata key found: #{keys.join(', ')}"
              raise Errors::DecryptionError, msg
            end

            unless POSSIBLE_ENCRYPTION_FORMATS.include? possible_envelope['x-amz-c']
              alg = possible_envelope['x-amz-c'].inspect
              msg = "unsupported content encrypting key (cek) format: #{alg} #{possible_envelope.inspect}"
              raise Errors::DecryptionError, msg
            end
            unless POSSIBLE_WRAPPING_FORMATS.include? possible_envelope['x-amz-w']
              alg = possible_envelope['x-amz-w'].inspect
              msg = "unsupported key wrapping algorithm: #{alg}"
              raise Errors::DecryptionError, msg
            end
            unless (missing_keys = REQUIRED_ENVELOPE_KEYS - possible_envelope.keys).empty?
              ##= ../specification/s3-encryption/data-format/content-metadata.md#determining-s3ec-object-status
              ##% In general, if there is any deviation from the above format, with the exception of additional unrelated mapkeys, then the S3EC SHOULD throw an exception.
              msg = "incomplete v3 encryption envelope:\n"
              msg += "  missing: #{missing_keys.join(',')}\n"
              raise Errors::DecryptionError, msg
            end
            possible_envelope
          end
        end
      end
    end
  end
end

##= ../specification/s3-encryption/data-format/content-metadata.md#v3-only
##= type=exception
##= reason=This has never been supported in Ruby
##% This material description string MAY be encoded by the esoteric double-encoding scheme used by the S3 web server.

##= ../specification/s3-encryption/data-format/content-metadata.md#v3-only
##= type=exception
##= reason=This has never been supported in Ruby
##% This encryption context string MAY be encoded by the esoteric double-encoding scheme used by the S3 web server.
