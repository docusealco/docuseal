# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'base64'

module TwitterCldr
  module Segmentation
    class CategoryTable
      PACK_FMT_16 = 'NNn'.freeze

      class << self
        def load16(data)
          data = Base64.decode64(data)

          new(
            (0...data.size).step(10).map do |i|
              data[i...(i + 10)].unpack(PACK_FMT_16)
            end
          )
        end
      end

      attr_reader :values

      def initialize(values)
        @values = values
      end

      def get(codepoint)
        find(codepoint)[2]
      end

      def dump16
        data = ''.b.tap do |result|
          values.each do |vals|
            result << vals.pack(PACK_FMT_16)
          end
        end

        Base64.encode64(data)
      end

      private

      def find(codepoint)
        cache[codepoint] ||= values.bsearch do |entry|
          next -1 if codepoint < entry[0]
          next 1 if codepoint > entry[1]
          0
        end
      end

      def cache
        @cache ||= {}
      end
    end
  end
end
