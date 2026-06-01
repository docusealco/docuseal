# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Tokenizers
    class Token
      attr_accessor :value, :type

      def initialize(options = {})
        options.each_pair do |key, val|
          self.send("#{key.to_s}=", val)
        end
      end

      def to_hash
        { value: @value, type: @type }
      end

      def to_s
        @value
      end

      # overriding `to_s` also overrides `inspect`, so we have to redefine it manually
      def inspect
        "<#{self.class}: #{instance_variables.map {|v| "#{v}=#{instance_variable_get(v).inspect}" }.join(", ")}>"
      end
    end
  end
end