# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Parsers

    class InvalidNumberError < StandardError; end

    class NumberParser

      SEPARATOR_CHARS = ['.', ',', ' '].map do |char|
        char == ' ' ? '\s' : Regexp.escape(char)
      end.join

      def initialize(locale = TwitterCldr.locale, number_system = nil)
        @locale = locale
        @data_reader = TwitterCldr::DataReaders::NumberDataReader.new(
          locale, number_system: number_system
        )
      end

      def parse(number_text, options = {})
        options[:strict] = true unless options.include?(:strict)
        group, decimal = separators(options[:strict])
        tokens = tokenize(number_text, group, decimal)

        num_list, punct_list = tokens.partition { |t| t[:type] == :numeric }
        raise InvalidNumberError unless punct_valid?(punct_list)
        raise InvalidNumberError unless tokens.last && tokens.last[:type] == :numeric

        if punct_list.last && punct_list.last[:type] == :decimal
          result = num_list[0..-2].map { |num| num[:value] }.join.to_i
          result + num_list.last[:value].to_i / (10.0 ** num_list.last[:value].size)
        else
          num_list.map { |num| num[:value] }.join.to_i
        end
      end

      def try_parse(number_text, default = nil, options = {})
        begin
          result = parse(number_text, options)
        rescue InvalidNumberError
          result = nil
        end

        if block_given?
          yield(result)
        else
          result || default
        end
      end

      def valid?(number_text, options = {})
        parse(number_text, options)
        true
      rescue
        false
      end

      def self.is_numeric?(text, separators = SEPARATOR_CHARS)
        !!(text =~ /\A[0-9#{separators}]+\Z/)
      end

      protected

      def punct_valid?(punct_list)
        # all group, allowed one decimal at end
        punct_list.each_with_index.all? do |punct, index|
          punct[:type] == :group || (index == (punct_list.size - 1) && punct[:type] == :decimal)
        end
      end

      def separators(strict = false)
        group = strict ? group_separator : SEPARATOR_CHARS
        decimal = strict ? decimal_separator : SEPARATOR_CHARS
        [group, decimal]
      end

      def tokenize(number_text, group, decimal)
        match_data = number_text.scan(/([\d]*)([#{group}]{0,1})([\d]*)([#{decimal}]{0,1})([\d]*)/)
        (match_data.flatten || []).reject(&:empty?).map { |match| identify(match, group, decimal) }
      end

      def identify(text, group, decimal)
        result = { value: text }
        result[:type] = if self.class.is_numeric?(result[:value], "")
          :numeric
        else
          if result[:value] =~ /[#{group}]/
            :group
          elsif result[:value] =~ /[#{decimal}]/
            :decimal
          else
            nil
          end
        end
        result
      end

      def decimal_separator
        @decimal_separator ||= Regexp.escape(@data_reader.symbols[:decimal])
      end

      def group_separator
        @group_separator ||= Regexp.escape(@data_reader.symbols[:group])
      end

    end
  end
end
