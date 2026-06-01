require "yajl"
require_relative "../adapter"

module MultiJson
  module Adapters
    # Use the Yajl-Ruby library to dump/load.
    class Yajl < Adapter
      ParseError = ::Yajl::ParseError

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
        ::Yajl::Parser.new(symbolize_keys: options[:symbolize_keys]).parse(string)
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
        ::Yajl::Encoder.encode(object, options)
      end
    end
  end
end
