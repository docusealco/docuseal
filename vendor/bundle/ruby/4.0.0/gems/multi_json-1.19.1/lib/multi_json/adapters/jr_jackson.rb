require "jrjackson" unless defined?(JrJackson)
require_relative "../adapter"

module MultiJson
  module Adapters
    # Use the jrjackson.rb library to dump/load.
    class JrJackson < Adapter
      ParseError = ::JrJackson::ParseError

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
        ::JrJackson::Json.load(string, options)
      end

      if ::JrJackson::Json.method(:dump).arity == 1
        # Serialize a Ruby object to JSON
        #
        # @api private
        # @param object [Object] object to serialize
        # @param _ [Hash] serialization options (unused in this version)
        # @return [String] JSON string
        #
        # @example Serialize object to JSON
        #   adapter.dump({key: "value"}) #=> '{"key":"value"}'
        def dump(object, _)
          ::JrJackson::Json.dump(object)
        end
      else
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
          ::JrJackson::Json.dump(object, options)
        end
      end
    end
  end
end
