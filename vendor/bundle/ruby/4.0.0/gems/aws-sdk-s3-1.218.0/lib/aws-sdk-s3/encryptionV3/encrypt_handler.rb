# frozen_string_literal: true

require 'base64'

module Aws
  module S3
    module EncryptionV3
      # @api private
      class EncryptHandler < Seahorse::Client::Handler
        def call(context)
          envelope, cipher = context[:encryption][:cipher_provider]
                             .encryption_cipher(
                               kms_encryption_context: context[:encryption][:kms_encryption_context]
                             )
          context[:encryption][:cipher] = cipher
          apply_encryption_envelope(context, envelope)
          apply_encryption_cipher(context, cipher)
          apply_cse_user_agent(context)
          @handler.call(context)
        end

        private

        def apply_encryption_envelope(context, envelope)
          ##= ../specification/s3-encryption/data-format/metadata-strategy.md#instruction-file
          ##% The S3EC MUST support writing some or all (depending on format) content metadata to an Instruction File.
          if context[:encryption][:envelope_location] == :instruction_file
            suffix = context[:encryption][:instruction_file_suffix]
            instruction_envelop, metadata_envelop = split_for_instruction_file(envelope)

            context.client.put_object(
              bucket: context.params[:bucket],
              key: context.params[:key] + suffix,
              ##= ../specification/s3-encryption/data-format/metadata-strategy.md#instruction-file
              ##% The content metadata stored in the Instruction File MUST be serialized to a JSON string.
              ##% The serialized JSON string MUST be the only contents of the Instruction File.
              body: Json.dump(instruction_envelop)
            )
            context.params[:metadata] ||= {}
            context.params[:metadata].update(metadata_envelop)
          else
            context.params[:metadata] ||= {}
            context.params[:metadata].update(envelope)
          end
        end

        def apply_encryption_cipher(context, cipher)
          io = context.params[:body] || ''
          io = StringIO.new(io) if io.is_a? String
          context.params[:body] = IOEncrypter.new(cipher, io)
          context.params[:metadata] ||= {}
          # Leaving this in because even though this is years old
          # it is still important to *not* MD5 the plaintext
          # If there exists any old integration points still doing this
          # that upgrade from 1 to 3 this needs to still fail.
          if context.params.delete(:content_md5)
            raise ArgumentError, 'Setting content_md5 on client side '\
              'encrypted objects is deprecated.'
          end
          context.http_response.on_headers do
            context.params[:body].close
          end
        end

        def apply_cse_user_agent(context)
          if context.config.user_agent_suffix.nil?
            context.config.user_agent_suffix = EC_USER_AGENT
          elsif !context.config.user_agent_suffix.include? EC_USER_AGENT
            context.config.user_agent_suffix += " #{EC_USER_AGENT}"
          end
        end

        def split_for_instruction_file(envelop)
          ##= ../specification/s3-encryption/data-format/content-metadata.md#content-metadata-mapkeys
          ##% In the V3 format, the mapkeys "x-amz-c", "x-amz-d", and "x-amz-i" MUST be stored exclusively in the Object Metadata.
          ##= ../specification/s3-encryption/data-format/metadata-strategy.md#v3-instruction-files
          ##% - The V3 message format MUST store the mapkey "x-amz-c" and its value in the Object Metadata when writing with an Instruction File.
          ##% - The V3 message format MUST NOT store the mapkey "x-amz-c" and its value in the Instruction File.
          ##% - The V3 message format MUST store the mapkey "x-amz-d" and its value in the Object Metadata when writing with an Instruction File.
          ##% - The V3 message format MUST NOT store the mapkey "x-amz-d" and its value in the Instruction File.
          ##% - The V3 message format MUST store the mapkey "x-amz-i" and its value in the Object Metadata when writing with an Instruction File.
          ##% - The V3 message format MUST NOT store the mapkey "x-amz-i" and its value in the Instruction File.
          metadata_envelop = envelop.select { |k, _v| Decryption::METADATA_KEY.include?(k) }
          # Exclude the metadata keys rather than include the envelop keys
          # because there might be additional information
          ##= ../specification/s3-encryption/data-format/metadata-strategy.md#v3-instruction-files
          ##% - The V3 message format MUST store the mapkey "x-amz-3" and its value in the Instruction File.
          ##% - The V3 message format MUST store the mapkey "x-amz-w" and its value in the Instruction File.
          ##% - The V3 message format MUST store the mapkey "x-amz-m" and its value (when present in the content metadata) in the Instruction File.
          ##% - The V3 message format MUST store the mapkey "x-amz-t" and its value (when present in the content metadata) in the Instruction File.
          instruction_envelop = envelop.reject { |k, _v| Decryption::METADATA_KEY.include?(k) }

          [instruction_envelop, metadata_envelop]
        end
      end
    end
  end
end
