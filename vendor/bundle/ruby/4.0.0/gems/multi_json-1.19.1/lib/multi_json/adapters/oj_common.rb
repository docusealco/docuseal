require "rubygems/version"

module MultiJson
  module Adapters
    module OjCommon
      OJ_VERSION = Gem::Version.new(::Oj::VERSION)
      OJ_V2 = OJ_VERSION.segments.first == 2
      OJ_V3 = OJ_VERSION.segments.first == 3
      private_constant :OJ_VERSION, :OJ_V2, :OJ_V3

      if OJ_V3
        PRETTY_STATE_PROTOTYPE = {
          indent: "  ",
          space: " ",
          space_before: "",
          object_nl: "\n",
          array_nl: "\n",
          ascii_only: false
        }.freeze
        private_constant :PRETTY_STATE_PROTOTYPE
      end

      private

      # Prepare options for Oj.dump based on Oj version
      #
      # @api private
      # @param options [Hash] serialization options
      # @return [Hash] processed options for Oj.dump
      #
      # @example Prepare dump options
      #   prepare_dump_options(pretty: true)
      def prepare_dump_options(options)
        if OJ_V2
          options[:indent] = 2 if options[:pretty]
          options[:indent] = options[:indent].to_i if options[:indent]
        elsif OJ_V3
          options.merge!(PRETTY_STATE_PROTOTYPE.dup) if options.delete(:pretty)
        else
          raise "Unsupported Oj version: #{::Oj::VERSION}"
        end

        options
      end
    end
  end
end
