# frozen_string_literal: true

require "cgi/escape"
require "cgi/util" if RUBY_VERSION < "3.5"

module Aws
  # @api private
  module Util
    class << self

      def deep_merge(left, right)
        case left
        when Hash then left.merge(right) { |key, v1, v2| deep_merge(v1, v2) }
        when Array then right + left
        else right
        end
      end

      def copy_hash(hash)
        if Hash === hash
          deep_copy(hash)
        else
          raise ArgumentError, "expected hash, got `#{hash.class}`"
        end
      end

      def deep_copy(obj)
        case obj
        when nil then nil
        when true then true
        when false then false
        when Hash
          obj.inject({}) do |h, (k,v)|
            h[k] = deep_copy(v)
            h
          end
        when Array
          obj.map { |v| deep_copy(v) }
        else
          if obj.respond_to?(:dup)
            obj.dup
          elsif obj.respond_to?(:clone)
            obj.clone
          else
            obj
          end
        end
      end

      def monotonic_milliseconds
        if defined?(Process::CLOCK_MONOTONIC)
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
        else
          DateTime.now.strftime('%Q').to_i
        end
      end

      def monotonic_seconds
        monotonic_milliseconds / 1000.0
      end

      def str_2_bool(str)
        case str.to_s
        when "true" then true
        when "false" then false
        else
          nil
        end
      end

      # @param [Number] input
      # @return [Number, String] The serialized number
      def serialize_number(input)
        if input == ::Float::INFINITY then 'Infinity'
        elsif input == -::Float::INFINITY then '-Infinity'
        elsif input&.nan? then 'NaN'
        else
          input
        end
      end

      # @param [String] str
      # @return [Number] The input as a number
      def deserialize_number(str)
        case str
        when 'Infinity' then ::Float::INFINITY
        when '-Infinity' then -::Float::INFINITY
        when 'NaN' then ::Float::NAN
        when nil then nil
        else str.to_f
        end
      end

      # @param [String] value
      # @return [Time]
      def deserialize_time(value)
        case value
        when nil then nil
        when /^[\d.]+$/ then Time.at(value.to_f).utc
        else
          begin
            fractional_time = Time.parse(value).to_f
            Time.at(fractional_time).utc
          rescue ArgumentError
            raise "unhandled timestamp format `#{value}'"
          end
        end
      end

    end
  end
end
