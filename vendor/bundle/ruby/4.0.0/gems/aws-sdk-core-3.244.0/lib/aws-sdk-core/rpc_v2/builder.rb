# frozen_string_literal: true

require 'base64'

module Aws
  module RpcV2
    class Builder
      include Seahorse::Model::Shapes

      def initialize(rules, _options = {})
        @rules = rules
      end

      def serialize(params)
        # If the input shape is empty, do not set a body. This is
        # different than if the input shape is a structure with no members.
        return nil if @rules.shape.struct_class == EmptyStructure

        RpcV2.encode(format(@rules, params))
      end

      private

      def structure(ref, values)
        shape = ref.shape
        values.each_pair.with_object({}) do |(key, value), data|
          if shape.member?(key) && !value.nil?
            member_ref = shape.member(key)
            member_name = member_ref.location_name || key
            data[member_name] = format(member_ref, value)
          end
        end
      end

      def list(ref, values)
        member_ref = ref.shape.member
        values.collect { |value| format(member_ref, value) }
      end

      def map(ref, values)
        value_ref = ref.shape.value
        values.each.with_object({}) do |(key, value), data|
          data[key] = format(value_ref, value)
        end
      end

      def blob(value)
        (String === value ? value : value.read).force_encoding(Encoding::BINARY)
      end

      def format(ref, value)
        case ref.shape
        when StructureShape then structure(ref, value)
        when ListShape      then list(ref, value)
        when MapShape       then map(ref, value)
        when BlobShape      then blob(value)
        else value
        end
      end
    end
  end
end
