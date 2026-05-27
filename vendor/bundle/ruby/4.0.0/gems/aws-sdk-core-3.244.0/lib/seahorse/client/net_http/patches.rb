# frozen_string_literal: true

require 'net/http'

module Seahorse
  module Client
    # @api private
    module NetHttp
      # @api private
      module Patches
        def self.apply!
          Net::HTTPGenericRequest.prepend(RequestPatches)
        end

        # Patches intended to override Net::HTTP functionality
        module RequestPatches
          # For requests with bodies, Net::HTTP sets a default content type of:
          #   'application/x-www-form-urlencoded'
          # There are cases where we should not send content type at all.
          # Even when no body is supplied, Net::HTTP uses a default empty body
          # and sets it anyway. This patch disables the behavior when a Thread
          # local variable is set.
          # See: https://github.com/ruby/net-http/issues/205
          def supply_default_content_type
            return if Thread.current[:net_http_skip_default_content_type]

            super
          end

          # IO.copy_stream is capped at 16KB buffer so this patch intends to
          # increase its chunk size for better performance.
          # Only intended to use for S3 TM implementation.
          # See: https://github.com/ruby/net-http/blob/master/lib/net/http/generic_request.rb#L292
          def send_request_with_body_stream(sock, ver, path, f)
            return super unless (chunk_size = Thread.current[:net_http_override_body_stream_chunk])

            unless content_length || chunked?
              raise ArgumentError, 'Content-Length not given and Transfer-Encoding is not `chunked`'
            end

            supply_default_content_type
            write_header(sock, ver, path)
            wait_for_continue sock, ver if sock.continue_timeout
            if chunked?
              chunker = Chunker.new(sock)
              RequestIO.custom_stream(f, chunker, chunk_size)
              chunker.finish
            else
              RequestIO.custom_stream(f, sock, chunk_size)
            end
          end

          class RequestIO
            def self.custom_stream(src, dst, chunk_size)
              copied = 0
              while (chunk = src.read(chunk_size))
                dst.write(chunk)
                copied += chunk.bytesize
              end
              copied
            end
          end
        end
      end
    end
  end
end
