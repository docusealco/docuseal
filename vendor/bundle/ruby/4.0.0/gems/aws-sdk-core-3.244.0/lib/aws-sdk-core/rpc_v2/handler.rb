# frozen_string_literal: true

module Aws
  module RpcV2
    class Handler < Seahorse::Client::Handler
      # @param [Seahorse::Client::RequestContext] context
      # @return [Seahorse::Client::Response]
      def call(context)
        build_request(context)
        response = with_metric { @handler.call(context) }
        response.on(200..299) { |resp| resp.data = parse_body(context) }
        response.on(200..599) { |_resp| apply_request_id(context) }
        response
      end

      private

      def with_metric(&block)
        Aws::Plugins::UserAgent.metric('PROTOCOL_RPC_V2_CBOR', &block)
      end

      def build_request(context)
        context.http_request.headers['Smithy-Protocol'] = 'rpc-v2-cbor'
        context.http_request.headers['X-Amzn-Query-Mode'] = 'true' if query_compatible?(context)
        context.http_request.http_method = 'POST'
        context.http_request.body = build_body(context)
        build_url(context)
      end

      def build_url(context)
        base = context.http_request.endpoint
        service_name = context.config.api.metadata['targetPrefix']
        base.path += "/service/#{service_name}/operation/#{context.operation.name}"
      end

      def build_body(context)
        Builder.new(context.operation.input).serialize(context.params)
      end

      def parse_body(context)
        cbor = context.http_response.body_contents
        if (rules = context.operation.output)
          if cbor.is_a?(Array)
            # an array of emitted events
            if cbor[0].respond_to?(:response)
              # initial response exists
              # it must be the first event arrived
              resp_struct = cbor.shift.response
            else
              resp_struct = context.operation.output.shape.struct_class.new
            end

            rules.shape.members.each do |name, ref|
              if ref.eventstream
                resp_struct.send("#{name}=", cbor.to_enum)
              end
            end
            resp_struct
          else
            Parser.new(
              rules,
              query_compatible: query_compatible?(context)
            ).parse(cbor)
          end
        else
          EmptyStructure.new
        end
      end

      def apply_request_id(context)
        context[:request_id] = context.http_response.headers['x-amzn-requestid']
      end

      def query_compatible?(context)
        context.config.api.metadata.key?('awsQueryCompatible')
      end
    end
  end
end
