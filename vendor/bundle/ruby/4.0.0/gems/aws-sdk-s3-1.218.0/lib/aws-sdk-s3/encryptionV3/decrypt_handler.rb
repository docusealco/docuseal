# frozen_string_literal: true

require 'base64'

require 'logger'

module Aws
  module S3
    module EncryptionV3
      # @api private
      class DecryptHandler < Seahorse::Client::Handler
        @@warned_response_target_proc = false

        def call(context)
          attach_http_event_listeners(context)
          apply_cse_user_agent(context)

          if context[:response_target].is_a?(Proc) && !@@warned_response_target_proc
            @@warned_response_target_proc = true
            warn(':response_target is a Proc, or a block was provided. ' \
              'Read the entire object to the ' \
              'end before you start using the decrypted data. This is to ' \
              'verify that the object has not been modified since it ' \
              'was encrypted.')

          end

          @handler.call(context)
        end

        private

        def attach_http_event_listeners(context)
          context.http_response.on_headers(200) do
            ##= ../specification/s3-encryption/decryption.md#key-commitment
            ##% The S3EC MUST validate the algorithm suite used for decryption
            ##% against the key commitment policy before attempting to decrypt the content ciphertext.
            # This is because the commitment policy _always_ allows decrypting committing algorithms.
            # In the else branch we check to see if
            decrypter =
              if Aws::S3::EncryptionV3::Decryption.v3?(context)
                ##= ../specification/s3-encryption/data-format/content-metadata.md#determining-s3ec-object-status
                ##% - If the metadata contains "x-amz-3" and "x-amz-d" and "x-amz-i" then the object MUST be considered an S3EC-encrypted object using the V3 format.
                cipher, envelope = Aws::S3::EncryptionV3::Decryption.decryption_cipher(context)
                Aws::S3::EncryptionV3::Decryption.get_decrypter(context, cipher, envelope)
              else
                if context[:encryption][:commitment_policy] == :require_encrypt_require_decrypt
                  ##= ../specification/s3-encryption/decryption.md#key-commitment
                  ##% If the commitment policy requires decryption using a committing algorithm suite,
                  ##% and the algorithm suite associated with the object does not support key commitment, then the S3EC MUST throw an exception.
                  ##= ../specification/s3-encryption/key-commitment.md#commitment-policy
                  ##% When the commitment policy is REQUIRE_ENCRYPT_REQUIRE_DECRYPT, the S3EC MUST NOT allow decryption using algorithm suites which do not support key commitment.
                  raise Errors::NonCommittingDecryptionError
                end

                ##= ../specification/s3-encryption/key-commitment.md#commitment-policy
                ##% When the commitment policy is FORBID_ENCRYPT_ALLOW_DECRYPT, the S3EC MUST allow decryption using algorithm suites which do not support key commitment.
                ##= ../specification/s3-encryption/key-commitment.md#commitment-policy
                ##% When the commitment policy is REQUIRE_ENCRYPT_ALLOW_DECRYPT, the S3EC MUST allow decryption using algorithm suites which do not support key commitment.
                cipher, envelope = Aws::S3::EncryptionV2::Decryption.decryption_cipher(context)
                Aws::S3::EncryptionV2::Decryption.get_decrypter(context, cipher, envelope)
              end
            context.http_response.body = decrypter
          end

          context.http_response.on_success(200) do
            decrypter = context.http_response.body
            decrypter.finalize
            decrypter.io.rewind if decrypter.io.respond_to?(:rewind)
            context.http_response.body = decrypter.io
          end

          context.http_response.on_error do
            context.http_response.body = context.http_response.body.io if context.http_response.body.respond_to?(:io)
          end
        end

        def apply_cse_user_agent(context)
          if context.config.user_agent_suffix.nil?
            context.config.user_agent_suffix = EC_USER_AGENT
          elsif !context.config.user_agent_suffix.include? EC_USER_AGENT
            context.config.user_agent_suffix += " #{EC_USER_AGENT}"
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
