# frozen_string_literal: true

require_relative 'cbor'
require_relative 'rpc_v2/builder'
require_relative 'rpc_v2/content_type_handler'
require_relative 'rpc_v2/error_handler'
require_relative 'rpc_v2/handler'
require_relative 'rpc_v2/parser'

module Aws
  # @api private
  module RpcV2
    class << self
      # @param [Symbol,Class] engine
      #   Must be one of the following values:
      #
      #   * :cbor
      #
      def engine=(engine)
        @engine = Class === engine ? engine : load_engine(engine)
      end

      # @return [Class] Returns the default engine.
      #   One of:
      #
      #   * {CborEngine}
      #
      def engine
        set_default_engine unless @engine
        @engine
      end

      def encode(data)
        @engine.encode(data)
      end

      def decode(bytes)
        bytes.force_encoding(Encoding::BINARY)
        @engine.decode(bytes)
      end

      def set_default_engine
        [:cbor].each do |name|
          @engine ||= try_load_engine(name)
        end

        unless @engine
          raise 'Unable to find a compatible cbor library.'
        end
      end

      private

      def load_engine(name)
        require "aws-sdk-core/rpc_v2/#{name}_engine"
        const_name = name[0].upcase + name[1..-1] + 'Engine'
        const_get(const_name)
      end

      def try_load_engine(name)
        load_engine(name)
      rescue LoadError
        false
      end
    end

    set_default_engine
  end
end
