# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Localized

    class LocalizedArray < LocalizedObject
      include Enumerable

      def code_points_to_string
        TwitterCldr::Utils::CodePoints.to_string(base_obj)
      end

      def sort
        TwitterCldr::Collation::Collator.new(locale).sort(base_obj).localize
      end

      def sort!
        TwitterCldr::Collation::Collator.new(locale).sort!(base_obj)
        self
      end

      def formatter_const
        nil
      end

      def to_a
        @base_obj.dup
      end

      def to_sentence
        TwitterCldr::Formatters::ListFormatter.new(locale).format(base_obj)
      end

      def each
        if block_given?
          @base_obj.each { |val| yield val }
        else
          @base_obj.to_enum
        end
      end

      def to_yaml(options = {})
        TwitterCldr::Utils::YAML.dump(@base_obj, options)
      end
    end

  end
end
