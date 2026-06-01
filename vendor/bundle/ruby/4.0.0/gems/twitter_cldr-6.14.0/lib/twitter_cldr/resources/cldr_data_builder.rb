# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'nokogiri'

module TwitterCldr
  module Resources

    class CldrDataBuilder
      DEEP_MERGER = proc do |key, v1, v2|
        Hash === v1 && Hash === v2 ? v1.merge(v2, &DEEP_MERGER) : (v2 || v1)
      end

      attr_reader :cldr_locale

      def initialize(cldr_locale)
        @cldr_locale = cldr_locale
      end

      def merge_each_ancestor
        cldr_locale.ancestors.inject({}) do |result, ancestor_locale|
          deep_merge(yield(ancestor_locale), result)
        end
      end

      private

      def deep_merge(h1, h2)
        h1.merge(h2, &DEEP_MERGER)
      end
    end

  end
end
