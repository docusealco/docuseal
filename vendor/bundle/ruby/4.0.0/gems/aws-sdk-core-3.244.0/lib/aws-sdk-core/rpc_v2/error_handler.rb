# frozen_string_literal: true

module Aws
  module RpcV2
    # @api private
    class ErrorHandler < Aws::ErrorHandler

      def call(context)
        # Malformed responses should throw an http based error, so we check
        # 200 range for error handling only for this case.
        @handler.call(context).on(200..599) do |response|
          if !valid_response?(context)
            code, message, data = http_status_error(context)
            response.error = build_error(context, code, message, data)
          elsif (300..599).cover?(context.http_response.status_code)
            response.error = error(context)
          end
          response.data = nil
        end
      end

      private

      def valid_response?(context)
        req_header = context.http_request.headers['smithy-protocol']
        resp_header = context.http_response.headers['smithy-protocol']
        req_header == resp_header
      end

      def extract_error(body, context)
        data = RpcV2.decode(body)
        code = error_code(data, context)
        message = data['message']
        data = parse_error_data(context, body, code)
        [code, message, data]
      rescue Cbor::Error
        [http_status_error_code(context), '', EmptyStructure.new]
      end

      def error_code(data, context)
        # This is not correct per protocol tests. awsQueryError is intended to populate the
        # error code of the error class. The error class should come from __type. Query and
        # query compatible services currently have dynamic errors raised from error codes instead
        # of the modeled error class. However, changing this in this major version would break
        # existing usage.
        code =
          if aws_query_error?(context)
            aws_query_error_code(context)
          else
            data['__type']
          end
        if code
          code.split('#').last
        else
          http_status_error_code(context)
        end
      end

      def aws_query_error?(context)
        context.config.api.metadata['awsQueryCompatible'] &&
          context.http_response.headers['x-amzn-query-error']
      end

      def aws_query_error_code(context)
        query_header = context.http_response.headers['x-amzn-query-error']
        error, _type = query_header.split(';') # type not supported
        remove_prefix(error, context)
      end

      def remove_prefix(error_code, context)
        if (prefix = context.config.api.metadata['errorPrefix'])
          error_code.sub(/^#{prefix}/, '')
        else
          error_code
        end
      end

      def parse_error_data(context, body, code)
        data = EmptyStructure.new
        if (error_rules = context.operation.errors)
          error_rules.each do |rule|
            # match modeled shape name with the type(code) only
            # some type(code) might contains invalid characters
            # such as ':' (efs) etc
            match = rule.shape.name == code.gsub(/[^^a-zA-Z0-9]/, '')
            next unless match && rule.shape.members.any?

            data = Parser.new(rule).parse(body)
          end
        end
        data
      end
    end
  end
end
