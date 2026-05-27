# frozen_string_literal: true

module Aws
  module Stubbing
    module Protocols
      # @api private
      class Json

        def stub_data(api, operation, data)
          resp = Seahorse::Client::Http::Response.new
          resp.status_code = 200
          resp.headers['Content-Type'] = content_type(api)
          resp.headers['x-amzn-RequestId'] = 'stubbed-request-id'
          resp.body = build_body(operation, data)
          resp
        end

        def stub_error(error_code)
          resp = Seahorse::Client::Http::Response.new
          resp.status_code = 400
          resp.body = <<~JSON.strip
            {
              "code": #{error_code.inspect},
              "message": "stubbed-response-error-message"
            }
          JSON
          resp
        end

        private

        def content_type(api)
          "application/x-amz-json-#{api.metadata['jsonVersion']}"
        end

        def build_body(operation, data)
          Aws::Json::Builder.new(operation.output).to_json(data)
        end

      end
    end
  end
end
