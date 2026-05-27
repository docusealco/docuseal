require_relative "../adapter"
require_relative "../convertible_hash_keys"
require_relative "../vendor/okjson"

module MultiJson
  module Adapters
    # Use the vendored OkJson library to dump/load.
    class OkJson < Adapter
      include ConvertibleHashKeys

      ParseError = ::MultiJson::OkJson::Error

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
        result = ::MultiJson::OkJson.decode("[#{string}]").first
        options[:symbolize_keys] ? symbolize_keys(result) : result
      rescue ArgumentError # invalid byte sequence in UTF-8
        raise ParseError
      end

      # Serialize a Ruby object to JSON
      #
      # @api private
      # @param object [Object] object to serialize
      # @param _ [Hash] serialization options (unused)
      # @return [String] JSON string
      #
      # @example Serialize object to JSON
      #   adapter.dump({key: "value"}) #=> '{"key":"value"}'
      def dump(object, _ = {})
        ::MultiJson::OkJson.valenc(stringify_keys(object))
      end
    end
  end
end
