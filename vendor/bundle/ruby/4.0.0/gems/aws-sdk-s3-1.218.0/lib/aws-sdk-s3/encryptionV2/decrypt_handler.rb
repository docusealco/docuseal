# frozen_string_literal: true

require 'base64'

module Aws
  module S3
    module EncryptionV2
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
            decrypter = if Aws::S3::EncryptionV3::Decryption.v3?(context)
              cipher, envelope = Aws::S3::EncryptionV3::Decryption.decryption_cipher(context)
              Aws::S3::EncryptionV3::Decryption.get_decrypter(context, cipher, envelope)
            else
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
            if context.http_response.body.respond_to?(:io)
              context.http_response.body = context.http_response.body.io
            end
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
