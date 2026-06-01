require "oj"
require_relative "../adapter"
require_relative "oj_common"

module MultiJson
  module Adapters
    # Use the Oj library to dump/load.
    class Oj < Adapter
      include OjCommon

      defaults :load, mode: :strict, symbolize_keys: false
      defaults :dump, mode: :compat, time_format: :ruby, use_to_json: true

      # In certain cases OJ gem may throw JSON::ParserError exception instead
      # of its own class. Also, we can't expect ::JSON::ParserError and
      # ::Oj::ParseError to always be defined, since it's often not the case.
      # Because of this, we can't reference those classes directly and have to
      # do string comparison instead. This will not catch subclasses, but it
      # shouldn't be a problem since the library is not known to be using it
      # (at least for now).
      class ParseError < ::SyntaxError
        WRAPPED_CLASSES = %w[Oj::ParseError JSON::ParserError].freeze
        private_constant :WRAPPED_CLASSES

        # Case equality for exception matching in rescue clauses
        #
        # @api private
        # @param exception [Exception] exception to check
        # @return [Boolean] true if exception is a parse error
        #
        # @example Match parse errors in rescue
        #   rescue ParseError => e
        def self.===(exception)
          exception.is_a?(::SyntaxError) || WRAPPED_CLASSES.include?(exception.class.to_s)
        end
      end

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
        options[:symbol_keys] = options[:symbolize_keys]
        ::Oj.load(string, options)
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
