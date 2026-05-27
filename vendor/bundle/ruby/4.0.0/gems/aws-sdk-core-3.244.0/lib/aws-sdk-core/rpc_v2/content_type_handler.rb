# frozen_string_literal: true

module Aws
  module RpcV2
    class ContentTypeHandler < Seahorse::Client::Handler
      def call(context)
        content_type =
          if eventstream_input?(context)
            'application/vnd.amazon.eventstream'
          elsif !empty_input_structure?(context)
            'application/cbor'
          end
        accept =
          if eventstream_output?(context)
            'application/vnd.amazon.eventstream'
          else
            'application/cbor'
          end

        headers = context.http_request.headers
        headers['Content-Type'] ||= content_type if content_type
        headers['Accept'] ||= accept
        @handler.call(context)
      end

      private

      def eventstream_input?(context)
        context.operation.input.shape.members.each do |_, ref|
          return true if ref.eventstream
        end
        false
      end

      def eventstream_output?(context)
        context.operation.output.shape.members.each do |_, ref|
          return true if ref.eventstream
        end
        false
      end

      def empty_input_structure?(context)
        context.operation.input.shape.struct_class == EmptyStructure
      end
    end
  end
end
