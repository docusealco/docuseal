# frozen_string_literal: true

module Aws
  module Stubbing
    module Protocols
      # @api private
      class RestJson < Rest

        def body_for(_a, _b, rules, data)
          if eventstream?(rules)
            encode_eventstream_response(rules, data, Aws::Json::Builder)
          else
            Aws::Json::Builder.new(rules).serialize(data)
          end
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

      end
    end
  end
end
