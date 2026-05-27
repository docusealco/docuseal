# frozen_string_literal: true

module Aws
  module Rest
    module Response
      class Body

        include Seahorse::Model::Shapes

        # @param [Class] parser_class
        # @param [Seahorse::Model::ShapeRef] rules
        def initialize(parser_class, rules)
          @parser_class = parser_class
          @rules = rules
        end

        # @param [IO] body
        # @param [Hash, Struct] data
        def apply(body, data)
          if event_stream?
            data[@rules[:payload]] = parse_eventstream(body)
          elsif streaming?
            # empty blob payloads are omitted
            data[@rules[:payload]] = body unless empty_blob_payload?(body)
          elsif @rules[:payload]
            data[@rules[:payload]] = parse(body.read, @rules[:payload_member])
          elsif !@rules.shape.member_names.empty?
            parse(body.read, @rules, data)
          end
        end

        private

        def empty_blob_payload?(body)
          true if non_streaming_blob_payload? && empty_body?(body)
        end

        def non_streaming_blob_payload?
          @rules[:payload_member].shape.is_a?(BlobShape) &&
            !@rules[:payload_member]['streaming']
        end

        def empty_body?(body)
          body.respond_to?(:size) && body.size.zero?
        end

        def event_stream?
          @rules[:payload] && @rules[:payload_member].eventstream
        end

        def streaming?
          @rules[:payload] && (
            BlobShape === @rules[:payload_member].shape ||
            StringShape === @rules[:payload_member].shape
          )
        end

        def parse(body, rules, target = nil)
          @parser_class.new(rules).parse(body, target) if body.size > 0
        end

        def parse_eventstream(body)
          # body contains an array of parsed event when they arrive
          @rules[:payload_member].shape.struct_class.new do |payload|
            body.each { |event| payload << event }
          end
        end

      end
    end
  end
end
