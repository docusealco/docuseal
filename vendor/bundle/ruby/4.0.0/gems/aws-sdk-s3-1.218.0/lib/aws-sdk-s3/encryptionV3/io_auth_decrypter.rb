# frozen_string_literal: true

module Aws
  module S3
    module EncryptionV3
      # @api private
      class IOAuthDecrypter
        # @option options [required, IO#write] :io
        #   An IO-like object that responds to {#write}.
        # @option options [required, Integer] :encrypted_content_length
        #   The number of bytes to decrypt from the `:io` object.
        #   This should be the total size of `:io` minus the length of
        #   the cipher auth tag.
        # @option options [required, OpenSSL::Cipher] :cipher An initialized
        #   cipher that can be used to decrypt the bytes as they are
        #   written to the `:io` object.
        def initialize(options = {})
          @decrypter = IODecrypter.new(options[:cipher], options[:io])
          @max_bytes = options[:encrypted_content_length]
          @bytes_written = 0
          @cipher = options[:cipher]
          @auth_tag = String.new
        end

        def write(chunk)
          chunk = truncate_chunk(chunk)
          return unless chunk.bytesize.positive?

          @bytes_written += chunk.bytesize
          @decrypter.write(chunk)
        end

        def finalize
          @cipher.auth_tag = @auth_tag
          @decrypter.finalize
        end

        def io
          @decrypter.io
        end

        private

        def truncate_chunk(chunk)
          if chunk.bytesize + @bytes_written <= @max_bytes
            chunk
          elsif @bytes_written < @max_bytes
            @auth_tag << chunk[@max_bytes - @bytes_written..-1]
            chunk[0..(@max_bytes - @bytes_written - 1)]
          else
            @auth_tag << chunk
            # If the tag was sent over after the full body has been read,
            # we don't want to accidentally append it.
            ''
          end
        end
      end
    end
  end
end
