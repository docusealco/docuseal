# frozen_string_literal: true

require_relative 'json/builder'
require_relative 'json/error_handler'
require_relative 'json/handler'
require_relative 'json/parser'

module Aws
  # @api private
  module Json
    class ParseError < StandardError
      def initialize(error)
        @error = error
        super(error.message)
      end

      attr_reader :error
    end

    class << self
      # @param [Symbol,Class] engine
      #   Must be one of the following values:
      #
      #   * :oj
      #   * :json
      #
      def engine=(engine)
        @engine = Class === engine ? engine : load_engine(engine)
      end

      # @return [Class] Returns the default engine.
      #   One of:
      #
      #   * {OjEngine}
      #   * {JsonEngine}
      #
      def engine
        set_default_engine unless @engine
        @engine
      end

      def load(json)
        @engine.load(json)
      end

      def dump(value)
        @engine.dump(value)
      end

      def set_default_engine
        [:oj, :json].each do |name|
          @engine ||= try_load_engine(name)
        end
        unless @engine
          raise 'Unable to find a compatible json library. ' \
          'Ensure that you have installed or added to your Gemfile one of ' \
          'oj or json'
        end
      end

      private

      def load_engine(name)
        require "aws-sdk-core/json/#{name}_engine"
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
