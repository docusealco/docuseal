require_relative "../adapter"
require "json"

module MultiJson
  module Adapters
    # Use the JSON gem to dump/load.
    class JsonGem < Adapter
      ParseError = ::JSON::ParserError

      defaults :load, create_additions: false, quirks_mode: true

      PRETTY_STATE_PROTOTYPE = {
        indent: "  ",
        space: " ",
        object_nl: "\n",
        array_nl: "\n"
      }.freeze
      private_constant :PRETTY_STATE_PROTOTYPE

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
        string = string.dup.force_encoding(Encoding::UTF_8) if string.encoding != Encoding::UTF_8

        options[:symbolize_names] = true if options.delete(:symbolize_keys)
        ::JSON.parse(string, options)
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
        opts = options.except(:adapter)
        json_object = object.respond_to?(:as_json) ? object.as_json : object
        return ::JSON.dump(json_object) if opts.empty?

        if opts.delete(:pretty)
          opts = PRETTY_STATE_PROTOTYPE.merge(opts)
          return ::JSON.pretty_generate(json_object, opts)
        end

        ::JSON.generate(json_object, opts)
      end
    end
  end
end
