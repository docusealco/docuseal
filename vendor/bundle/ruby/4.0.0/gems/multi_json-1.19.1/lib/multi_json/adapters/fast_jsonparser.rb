require "fast_jsonparser"
require "oj"
require_relative "../adapter"
require_relative "oj_common"

module MultiJson
  module Adapters
    # Use the FastJsonparser library to load and Oj to dump.
    class FastJsonparser < Adapter
      include OjCommon

      defaults :load, symbolize_keys: false
      defaults :dump, mode: :compat, time_format: :ruby, use_to_json: true

      ParseError = ::FastJsonparser::ParseError

      # Parse a JSON string into a Ruby object
      #
      # @api private
      # @param string [String] JSON string to parse
      # @param options [Hash] parsing options
      # @return [Object] parsed Ruby object
      #
      # @example Parse JSON string
      #   adapter.load('{"key":"value"}') #=> {"key" => "value"}
      def load(string, options = {})
        ::FastJsonparser.parse(string, symbolize_keys: options[:symbolize_keys])
      end

      # Serialize a Ruby object to JSON
      #
      # @api private
      # @param object [Object] object to serialize
      # @param options [Hash] serialization options
      # @return [String] JSON string
      #
      # @example Serialize object to JSON
      #   adapter.dump({key: "value"}) #=> '{"key":"value"}'
      def dump(object, options = {})
        ::Oj.dump(object, prepare_dump_options(options))
      end
    end
  end
end
