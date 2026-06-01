# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Localized

    class LocalizedString < LocalizedObject
      include Enumerable

      # Uses wrapped string object as a format specification and returns the result of applying it to +args+ (see
      # standard String#% method documentation for interpolation syntax).
      #
      # If +args+ is a Hash than pluralization is performed before interpolation (see +PluralFormatter+ class for
      # pluralization specification).
      #
      def %(args)
        pluralized = args.is_a?(Hash) ? formatter.format(@base_obj, args) : @base_obj
        escape_plural_interpolation(pluralized) % args
      end

      def normalize(options = {})
        TwitterCldr::Normalization.normalize(@base_obj, options).localize(locale)
      end

      def casefold(options = {})
        unless options.include?(:t)
          # Turkish and azerbaijani use the dotless i and therefore have a few
          # special casefolding rules. Note "az" is not actually supported yet.
          options[:t] = [:tr, :az].include?(locale)
        end

        TwitterCldr::Shared::Casefolder.
          casefold(@base_obj, options[:t]).
          localize(locale)
      end

      def downcase
        self.class.new(
          TwitterCldr::Shared::Caser.downcase(@base_obj), locale
        )
      end

      def upcase
        self.class.new(
          TwitterCldr::Shared::Caser.upcase(@base_obj), locale
        )
      end

      def titlecase
        self.class.new(
          TwitterCldr::Shared::Caser.titlecase(@base_obj), locale
        )
      end

      def each_sentence
        if block_given?
          break_iterator.each_sentence(@base_obj) do |sentence|
            yield sentence.localize(locale)
          end
        else
          to_enum(__method__)
        end
      end

      def each_word
        if block_given?
          break_iterator.each_word(@base_obj) do |word|
            yield word.localize(locale)
          end
        else
          to_enum(__method__)
        end
      end

      def hyphenate(delimiter = nil)
        hyphenated_str = @base_obj.dup

        break_iterator.each_word(@base_obj).reverse_each do |word, start, stop|
          hyphenated_str[start...stop] = hyphenator.hyphenate(word, delimiter)
        end

        hyphenated_str.localize(locale)
      end

      def code_points
        TwitterCldr::Utils::CodePoints.from_string(@base_obj)
      end

      def to_s
        @base_obj.dup
      end

      def to_i(options = {})
        to_f(options).to_i
      end

      def to_f(options = {})
        if number_parser.class.is_numeric?(@base_obj)
          number_parser.try_parse(@base_obj, options) do |result|
            result || @base_obj.to_f
          end
        else
          @base_obj.to_f
        end
      end

      def size
        code_points.size
      end

      alias :length :size

      def bytesize
        @base_obj.bytesize
      end

      def [](index)
        if index.is_a?(Range)
          TwitterCldr::Utils::CodePoints.to_string(code_points[index])
        else
          TwitterCldr::Utils::CodePoints.to_char(code_points[index])
        end
      end

      def each_char
        if block_given?
          code_points.each do |code_point|
            yield TwitterCldr::Utils::CodePoints.to_char(code_point)
          end
          @base_obj
        else
          code_points.map { |code_point| TwitterCldr::Utils::CodePoints.to_char(code_point) }.to_enum
        end
      end

      alias :each :each_char

      def to_yaml(options = {})
        TwitterCldr::Utils::YAML.dump(@base_obj, options)
      end

      def to_bidi(options = {})
        TwitterCldr::Shared::Bidi.from_string(@base_obj, options)
      end

      def to_reordered_s(options = {})
        to_bidi(options).reorder_visually!.to_s
      end

      def to_territory
        TwitterCldr::Shared::Territory.new(@base_obj)
      end

      def scripts
        TwitterCldr::Utils::ScriptDetector.detect_scripts(@base_obj).scripts
      end

      def script
        TwitterCldr::Utils::ScriptDetector.detect_scripts(@base_obj).best_guess
      end

      def transliterate_into(target_locale)
        TwitterCldr::Transforms::Transliterator.transliterate(@base_obj, locale, target_locale)
      end

      private

      def escape_plural_interpolation(string)
        # escape plural interpolation patterns (see PluralFormatter)
        string.gsub(TwitterCldr::Formatters::PluralFormatter::PLURALIZATION_REGEXP, '%\0')
      end

      def formatter
        @formatter ||=
          TwitterCldr::Formatters::PluralFormatter.for_locale(locale)
      end

      def break_iterator
        @break_iterator ||= TwitterCldr::Segmentation::BreakIterator.new(locale)
      end

      def number_parser
        @number_parser ||= TwitterCldr::Parsers::NumberParser.new(locale)
      end

      def hyphenator
        @hyphenator ||= TwitterCldr::Shared::Hyphenator.get(locale)
      end

    end

  end
end
