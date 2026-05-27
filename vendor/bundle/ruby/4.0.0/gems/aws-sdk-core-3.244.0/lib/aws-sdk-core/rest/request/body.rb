# frozen_string_literal: true

module Aws
  module Rest
    module Request
      class Body

        include Seahorse::Model::Shapes

        # @param [Class] serializer_class
        # @param [Seahorse::Model::ShapeRef] rules
        def initialize(serializer_class, rules)
          @serializer_class = serializer_class
          @rules = rules
        end

        # @param [Seahorse::Client::Http::Request] http_req
        # @param [Hash] params
        def apply(http_req, params)
          body = build_body(params)

          # for rest-json, ensure we send at least an empty object
          # don't send an empty object for streaming? case.
          if body.nil? &&
             json_builder? &&
             modeled_body? &&
             !streaming?
            body = '{}'
          end
          http_req.body = body
        end

        private

        # operation is modeled for body when it is modeled for a payload
        # either with payload trait or normal members.
        def modeled_body?
          return true if @rules[:payload]
          @rules.shape.members.each do |member|
            _name, shape = member
            return true if shape.location.nil?
          end
          false
        end

        def build_body(params)
          if streaming?
            params[@rules[:payload]]
          elsif @rules[:payload]
            params = params[@rules[:payload]]
            if params
              if xml_builder? &&
                 @rules.shape.member?(@rules[:payload_member].location_name)
                # serializing payload member name for rest-xml is as follows:
                # 1. Use the member locationName if the member value doesn't match the member's name (default)
                # 2. Use the value of the locationName on the member's target if present
                # 3. Use the shape name of the member's target
                serialize(@rules[:payload_member], params, location_name: payload_location_name)
              else
                serialize(@rules[:payload_member], params)
              end
            end
          else
            params = body_params(params)
            serialize(@rules, params) unless params.empty?
          end
        end

        def payload_location_name
          @rules[:payload_member].shape['locationName'] ||
            @rules[:payload_member].shape.name
        end

        def streaming?
          @rules[:payload] && (
            BlobShape === @rules[:payload_member].shape ||
            StringShape === @rules[:payload_member].shape
          )
        end

        def xml_builder?
          @serializer_class == Xml::Builder
        end

        def json_builder?
          @serializer_class == Json::Builder
        end

        def serialize(rules, params, location_name: nil)
          @serializer_class.new(rules, location_name: location_name).serialize(params)
        end

        def body_params(params)
          @rules.shape.members.inject({}) do |hash, (member_name, member_ref)|
            if !member_ref.location && params.key?(member_name)
              hash[member_name] = params[member_name]
            end
            hash
          end
        end

      end
    end
  end
end
