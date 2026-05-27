# frozen_string_literal: true

module Aws
  module Plugins

    # For Streaming Input Operations, when `requiresLength` is enabled
    # checking whether `Content-Length` header can be set,
    # for `unsignedPayload` and `v4-unsigned-body` operations,
    # set `Transfer-Encoding` header.
    class TransferEncoding < Seahorse::Client::Plugin

      # @api private
      class Handler < Seahorse::Client::Handler
        def call(context)
          if streaming?(context.operation.input)
            # If it's an IO object and not a File / String / String IO
            unless context.http_request.body.respond_to?(:size)
              if requires_length?(context.operation.input)
                # if size of the IO is not available but required
                raise Aws::Errors::MissingContentLength
              elsif unsigned_payload?(context.operation)
                context.http_request.headers['Transfer-Encoding'] = 'chunked'
              end
            end
          end

          @handler.call(context)
        end

        private

        def streaming?(ref)
          if (payload = ref[:payload_member])
            payload['streaming'] || payload.shape['streaming']
          else
            false
          end
        end

        def unsigned_payload?(operation)
          operation['unsignedPayload'] ||
            operation['authtype'] == 'v4-unsigned-body'
        end

        def requires_length?(ref)
          if (payload = ref[:payload_member])
            payload['requiresLength'] || payload.shape['requiresLength']
          else
            false
          end
        end

      end

      handler(Handler, step: :sign)

    end

  end
end
