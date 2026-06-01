# frozen_string_literal: true

module Aws
  # @api private
  module Rest
    class Handler < Seahorse::Client::Handler

      def call(context)
        Rest::Request::Builder.new.apply(context)
        response = @handler.call(context)
        response.on(200..299) { |resp| Response::Parser.new.apply(resp) }
        response.on(200..599) { |_resp| apply_request_id(context) }
      end

      private

      def apply_request_id(context)
        h = context.http_response.headers
        context[:request_id] ||= h['x-amz-request-id'] || h['x-amzn-requestid']
      end

    end
  end
end
