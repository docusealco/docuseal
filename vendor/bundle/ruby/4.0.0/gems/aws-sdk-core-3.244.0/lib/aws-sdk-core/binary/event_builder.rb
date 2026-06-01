# frozen_string_literal: true

module Aws
  module Binary
    # @api private
    class EventBuilder

      include Seahorse::Model::Shapes

      # @param [Class] serializer_class
      # @param [Seahorse::Model::ShapeRef] rules (of eventstream member)
      def initialize(serializer_class, rules)
        @serializer_class = serializer_class
        @rules = rules
      end

      def apply(event_type, params)
        event_ref = @rules.shape.member(event_type)
        _event_stream_message(event_ref, params)
      end

      private

      def _event_stream_message(event_ref, params)
        es_headers = {}
        payload = ""

        es_headers[":message-type"] = Aws::EventStream::HeaderValue.new(
          type: "string", value: "event")
        es_headers[":event-type"] = Aws::EventStream::HeaderValue.new(
          type: "string", value: event_ref.location_name)

        explicit_payload = false
        implicit_payload_members = {}
        event_ref.shape.members.each do |member_name, member_ref|
          unless member_ref.eventheader
            if member_ref.eventpayload
              explicit_payload = true
            else
              implicit_payload_members[member_name] = member_ref
            end
          end
        end

        # handle header members for all cases
        event_ref.shape.members.each do |member_name, member_ref|
          if member_ref.eventheader && params[member_name]
            header_value = params[member_name]
            es_headers[member_ref.shape.name] = Aws::EventStream::HeaderValue.new(
              type: header_value_type(member_ref.shape, header_value),
              value: header_value
            )
          end
        end

        # implict payload
        if !explicit_payload && !implicit_payload_members.empty?
          payload_shape = StructureShape.new
          implicit_payload_members.each do |m_name, m_ref|
            payload_shape.add_member(m_name, m_ref)
          end
          payload_ref = ShapeRef.new(shape: payload_shape)

          payload = build_payload_members(payload_ref, params)
                      .force_encoding(Encoding::BINARY)


          es_headers[":content-type"] = Aws::EventStream::HeaderValue.new(
            type: "string", value: content_type(payload_ref.shape))
        else
          # explicit payload, serialize just the payload member
          event_ref.shape.members.each do |member_name, member_ref|
            if member_ref.eventpayload && params[member_name]
              es_headers[":content-type"] = Aws::EventStream::HeaderValue.new(
                type: "string", value: content_type(member_ref.shape))
              payload = params[member_name]
            end
          end
        end

        Aws::EventStream::Message.new(
          headers: es_headers,
          payload: StringIO.new(payload)
        )
      end

      def content_type(shape)
        case shape
        when BlobShape then "application/octet-stream"
        when StringShape then "text/plain"
        when StructureShape then
          if @serializer_class.name.include?('Xml')
            "text/xml"
          elsif @serializer_class.name.include?('Json')
            "application/json"
          end
        else
          raise Aws::Errors::EventStreamBuilderError.new(
            "Unsupport eventpayload shape: #{shape.name}")
        end
      end

      def header_value_type(shape, value)
        case shape
        when StringShape then "string"
        when IntegerShape then "integer"
        when TimestampShape then "timestamp"
        when BlobShape then "bytes"
        when BooleanShape then !!value ? "bool_true" : "bool_false"
        else
          raise Aws::Errors::EventStreamBuilderError.new(
            "Unsupported eventheader shape: #{shape.name}")
        end
      end

      def build_payload_members(payload_ref, params)
        @serializer_class.new(payload_ref).serialize(params)
      end
    end
  end
end
