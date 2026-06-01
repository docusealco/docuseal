# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module DataReaders
    class TimespanDataReader < DataReader
      DEFAULT_DIRECTION = :ago
      DEFAULT_TYPE = :default
      VALID_FIELDS = [:second, :minute, :hour, :day, :week, :month, :year]
      BASE_PATH = [:fields]

      attr_reader :direction, :unit, :type, :plural_rule

      def initialize(locale, seconds, options = {})
        super(locale)

        @type = options[:type] || DEFAULT_TYPE
        @direction = options[:direction] || DEFAULT_DIRECTION
        @unit = options[:unit]

        @plural_rule = options[:plural_rule] ||
          TwitterCldr::Formatters::Plurals::Rules.rule_for(seconds, locale)
      end

      def pattern
        traverse(path)
      end

      def tokenizer
        @tokenizer ||= TwitterCldr::Tokenizers::TimespanTokenizer.new(self)
      end

      def formatter
        @formatter ||= TwitterCldr::Formatters::TimespanFormatter.new(self)
      end

      private

      def path
        BASE_PATH + [type_field, :relative_time, direction_field, plural_rule]
      end

      def direction_field
        case direction
          when :ago
            :past
          else
            :future
        end
      end

      def type_field
        case type
          when :default
            unit
          else
            :"#{unit}-#{type}"
        end
      end

      def resource
        @resource ||= TwitterCldr.get_locale_resource(locale, :fields)[locale]
      end
    end
  end
end
