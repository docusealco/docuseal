# frozen_string_literal: true

module Aws
  module Stubbing
    module Protocols
      # @api private
      class RpcV2

        def stub_data(_api, operation, data)
          resp = Seahorse::Client::Http::Response.new
          resp.status_code = 200
          resp.headers['Smithy-Protocol'] = 'rpc-v2-cbor'
          resp.headers['Content-Type'] = 'application/cbor'
          resp.headers['x-amzn-RequestId'] = 'stubbed-request-id'
          resp.body = build_body(operation, data)
          resp
        end

        def stub_error(error_code)
          resp = Seahorse::Client::Http::Response.new
          resp.status_code = 400
          resp.body = Aws::RpcV2.encode(
            {
              'code' => error_code,
              'message' => 'stubbed-response-error-message'
            }
          )
          resp
        end

        private

        def build_body(operation, data)
          Aws::RpcV2::Builder.new(operation.output).serialize(data)
        end
      end
    end
  end
end
