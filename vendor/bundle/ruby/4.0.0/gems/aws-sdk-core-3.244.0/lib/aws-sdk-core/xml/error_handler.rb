# frozen_string_literal: true

require "cgi/escape"
require "cgi/util" if RUBY_VERSION < "3.5"

module Aws
  module Xml
    # @api private
    class ErrorHandler < Aws::ErrorHandler

      def call(context)
        @handler.call(context).on(300..599) do |response|
          response.error = error(context) unless response.error
          response.data = nil
        end
      end

      private

      def extract_error(body, context)
        context[:request_id] = request_id(body)
        code = error_code(body, context)
        [
          code,
          error_message(body),
          error_data(context, body, code)
        ]
      end

      def error_data(context, body, code)
        data = EmptyStructure.new
        if (error_rules = context.operation.errors)
          error_rules.each do |rule|
            # query protocol may have custom error code
            # reference: https://smithy.io/2.0/aws/protocols/aws-query-protocol.html#error-code-resolution
            error_shape_code = rule.shape['error']['code'] if rule.shape['error']
            match = (code == error_shape_code || code == rule.shape.name)
            next unless match && rule.shape.members.any?

            data = parse_error_data(rule, body)
            # supporting HTTP bindings
            apply_error_headers(rule, context, data)
          end
        end
        data
      rescue Xml::Parser::ParsingError
        EmptyStructure.new
      end

      def parse_error_data(rule, body)
        # errors may nested under <Errors><Error>structure_data</Error></Errors>
        # Or may be flat and under <Error>structure_data</Error>
        body = body.tr("\n", '')
        if (matches = body.match(/<Error>(.+?)<\/Error>/))
          Parser.new(rule).parse("<#{rule.shape.name}>#{matches[1]}</#{rule.shape.name}>")
        else
          EmptyStructure.new
        end
      end

      def apply_error_headers(rule, context, data)
        headers = Aws::Rest::Response::Headers.new(rule)
        headers.apply(context.http_response, data)
      end

      def error_code(body, context)
        if (matches = body.match(/<Code>(.+?)<\/Code>/))
          remove_prefix(unescape(matches[1]), context)
        else
          http_status_error_code(context)
        end
      end

      def remove_prefix(error_code, context)
        if (prefix = context.config.api.metadata['errorPrefix'])
          error_code.sub(/^#{prefix}/, '')
        else
          error_code
        end
      end

      def error_message(body)
        if (matches = body.match(/<Message>(.+?)<\/Message>/m))
          unescape(matches[1])
        else
          ''
        end
      end

      def request_id(body)
        if (matches = body.match(/<RequestId>(.+?)<\/RequestId>/m))
          matches[1]
        end
      end

      def unescape(str)
        CGI.unescapeHTML(str)
      end

    end
  end
end
