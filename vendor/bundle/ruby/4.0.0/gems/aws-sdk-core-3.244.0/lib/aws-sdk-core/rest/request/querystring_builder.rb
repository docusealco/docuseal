# frozen_string_literal: true

module Aws
  module Rest
    module Request
      class QuerystringBuilder
        include Seahorse::Model::Shapes

        SUPPORTED_TYPES = [
          BooleanShape,
          FloatShape,
          IntegerShape,
          StringShape,
          TimestampShape
        ].freeze

        # Provide shape references and param values:
        #
        #     [
        #       [shape_ref1, 123],
        #       [shape_ref2, "text"]
        #     ]
        #
        # Returns a querystring:
        #
        #   "Count=123&Words=text"
        #
        # @param [Array<Array<Seahorse::Model::ShapeRef, Object>>] params An array of
        #   model shape references and request parameter value pairs.
        #
        # @return [String] Returns a built querystring
        def build(params)
          # keys in query maps must NOT override other keys
          query_keys = query_keys(params)
          params.map do |(shape_ref, param_value)|
            build_part(shape_ref, param_value, query_keys)
          end.reject { |p| p.nil? || p.empty? }.join('&')
        end

        private

        def query_keys(params)
          keys = Set.new
          params.each do |(shape_ref, _)|
            keys << shape_ref.location_name unless shape_ref.shape.is_a?(MapShape)
          end
          keys
        end

        def build_part(shape_ref, param_value, query_keys)
          case shape_ref.shape
          # supported scalar types
          when *SUPPORTED_TYPES
            "#{shape_ref.location_name}=#{query_value(shape_ref, param_value)}"
          when MapShape
            generate_query_map(shape_ref, param_value, query_keys)
          when ListShape
            generate_query_list(shape_ref, param_value)
          else
            raise NotImplementedError
          end
        end

        def timestamp(ref, value)
          case ref['timestampFormat'] || ref.shape['timestampFormat']
          when 'unixTimestamp' then value.to_i
          when 'rfc822' then value.utc.httpdate
          else
            # querystring defaults to iso8601
            value.utc.iso8601
          end
        end

        def query_value(ref, value)
          case ref.shape
          when TimestampShape
            escape(timestamp(ref, value))
          when *SUPPORTED_TYPES
            escape(value.to_s)
          else
            raise NotImplementedError
          end
        end

        def generate_query_list(ref, values)
          member_ref = ref.shape.member
          values.map do |value|
            value = query_value(member_ref, value)
            "#{ref.location_name}=#{value}"
          end
        end

        def generate_query_map(ref, value, query_keys)
          case ref.shape.value.shape
          when StringShape
            query_map_of_string(value, query_keys)
          when ListShape
            query_map_of_string_list(value, query_keys)
          else
            msg = 'Only map of string and string list supported'
            raise NotImplementedError, msg
          end
        end

        def query_map_of_string(hash, query_keys)
          list = []
          hash.each_pair do |key, value|
            key = escape(key)
            list << "#{key}=#{escape(value)}" unless query_keys.include?(key)
          end
          list
        end

        def query_map_of_string_list(hash, query_keys)
          list = []
          hash.each_pair do |key, values|
            key = escape(key)
            values.each do |value|
              list << "#{key}=#{escape(value)}" unless query_keys.include?(key)
            end
          end
          list
        end

        def escape(string)
          Seahorse::Util.uri_escape(string)
        end
      end
    end
  end
end
