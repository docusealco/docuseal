# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module DataReaders
    class NumberDataReader < DataReader

      PluralRules = TwitterCldr::Formatters::Plurals::Rules

      DEFAULT_NUMBER_SYSTEM = :default
      ABBREVIATED_MIN_POWER = 3
      ABBREVIATED_MAX_POWER = 14

      NUMBER_MIN = 10 ** ABBREVIATED_MIN_POWER
      NUMBER_MAX = 10 ** (ABBREVIATED_MAX_POWER + 1)

      PATTERN_PATH = [:numbers, :formats]
      SYMBOL_PATH  = [:numbers, :symbols]

      TYPES = [:default, :decimal, :currency, :percent]
      FORMATS = [:long, :short, :default]

      DEFAULT_TYPE = :decimal
      DEFAULT_FORMAT = :default
      DEFAULT_SIGN = :positive

      FORMATTERS = {
        decimal: TwitterCldr::Formatters::DecimalFormatter,
        currency: TwitterCldr::Formatters::CurrencyFormatter,
        percent: TwitterCldr::Formatters::PercentFormatter
      }

      attr_reader :type, :format, :number_system

      def self.types
        TYPES
      end

      def initialize(locale, options = {})
        super(locale)
        @type = options[:type] || DEFAULT_TYPE

        unless type && TYPES.include?(type.to_sym)
          raise ArgumentError.new("Type #{type} is not supported")
        end

        @format = options[:format] || DEFAULT_FORMAT
        @number_system = options[:number_system] || default_number_system
      end

      def format_number(number, options = {})
        precision = options[:precision] || 0
        pattern_for_number = pattern(number, precision == 0)
        options[:locale] = self.locale
        tokens = tokenizer.tokenize(pattern_for_number)
        formatter.format(tokens, number, options)
      end

      def pattern(number, decimal = true)
        zeroes = number.to_i.abs.to_s.size - 1
        magnitude = "1#{'0' * zeroes}"
        truncated_num = formatter.truncate_number(number, zeroes % 3 + 1)
        truncated_num = truncated_num.to_i if decimal
        plural_rule = PluralRules.rule_for(truncated_num, locale)

        path = PATTERN_PATH + [
          type,
          number_system,
          [format, :default],
          magnitude.to_sym,
          [plural_rule, :other]
        ]

        sign = number < 0 ? :negative : :positive

        pattern_for_sign(
          traverse_finding_best_fit(path, []), sign
        )
      end

      def symbols
        @symbols ||= traverse_following_aliases(SYMBOL_PATH + [number_system])
      end

      def tokenizer
        @tokenizer ||= TwitterCldr::Tokenizers::NumberTokenizer.new(self)
      end

      def formatter
        @formatter ||= FORMATTERS[type].new(self)
      end

      def default_number_system
        @default_number_system ||= resource[:numbers][:default_number_systems][:default].to_sym
      end

      def pattern_for_sign(pattern, sign)
        if pattern.include?(";")
          positive, negative = pattern.split(";")
          sign == :positive ? positive : negative
        else
          case sign
            when :negative
              "#{symbols[:minus_sign] || '-'}#{pattern}"
            else
              pattern
          end
        end
      end

      private

      def traverse_finding_best_fit(path_pattern, path, hash = resource)
        if path_pattern.empty?
          result = traverse_following_aliases(path, hash)
          return result if result.is_a?(String)
        else
          Array(path_pattern.first).each do |leg|
            result = traverse_finding_best_fit(path_pattern[1..-1], path + [leg], hash)
            return result if result
          end

          result = traverse_following_aliases(path, hash)
          return result if result.is_a?(String)
        end
      end

      def traverse_following_aliases(path, hash = resource)
        traverse(path, hash) do |_leg, leg_data|
          if leg_data.is_a?(Symbol) && leg_data.to_s.start_with?('numbers.')
            traverse_following_aliases(leg_data.to_s.split('.').map(&:to_sym))
          else
            leg_data
          end
        end
      end

      def resource
        @resource ||= begin
          raw = TwitterCldr.get_locale_resource(locale, :numbers)
          raw[TwitterCldr.convert_locale(locale)]
        end
      end

      def self.within_abbreviation_range?(number)
        abs_value = number.abs
        NUMBER_MIN <= abs_value && abs_value < NUMBER_MAX
      end
    end
  end
end
