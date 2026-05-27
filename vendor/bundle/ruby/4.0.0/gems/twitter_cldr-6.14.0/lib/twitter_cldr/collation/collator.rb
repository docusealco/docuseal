# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Collation

    class UnexpectedCodePointError < StandardError; end

    # Collator uses fractional collation elements table form CLDR to generate sort keys for Unicode strings as well as
    # compare and sort such strings by generated sort keys.
    #
    class Collator

      attr_accessor :locale

      def initialize(locale = nil)
        @locale  = TwitterCldr.convert_locale(locale) if locale
        @options = tailoring_options
        @trie    = load_trie
      end

      def sort(strings)
        strings.map{ |s| [s, get_sort_key(s)] }.sort{ |a, b| a[1] <=> b[1] }.map(&:first)
      end

      def sort!(strings)
        sort_keys = Hash.new { |hash, string| hash[string] = get_sort_key(string) }
        strings.replace(strings.sort_by { |s| sort_keys[s] })
      end

      def compare(string_a, string_b)
        string_a == string_b ? 0 : get_sort_key(string_a) <=> get_sort_key(string_b)
      end

      # Second arg options, supports an option :maximum_level, to
      # pass on to SortKeyBuilder :maximum_level.
      def get_sort_key(string_or_code_points, method_options = {})
        TwitterCldr::Collation::SortKeyBuilder.build(get_collation_elements(string_or_code_points), case_first: @options[:case_first], maximum_level: method_options[:maximum_level])
      end

      def get_collation_elements(string_or_code_points)
        code_points = get_normalized_code_points(string_or_code_points)

        result = []
        result.concat(code_point_collation_elements(code_points)) until code_points.empty?
        result
      end

      private

      def tailoring_options
        @locale ? TwitterCldr::Collation::TrieBuilder.tailoring_data(@locale)[:collator_options] : {}
      end

      def load_trie
        @locale ? self.class.tailored_trie(@locale) : self.class.default_trie
      end

      def get_normalized_code_points(str_or_code_points)
        str = if str_or_code_points.is_a?(String)
          str_or_code_points
        else
          TwitterCldr::Utils::CodePoints.to_string(str_or_code_points)
        end

        # Normalization makes the collation process significantly slower (like seven times slower on the UCA
        # non-ignorable test from CollationTest_NON_IGNORABLE.txt). ICU uses some optimizations to apply normalization
        # only in special, rare cases. We need to investigate possible solutions and do normalization cleverly too.
        TwitterCldr::Utils::CodePoints.from_string(
          TwitterCldr::Normalization.normalize(str)
        )
      rescue ArgumentError
        # Meant to rescue encoding errors. Some tests do not provide valid UTF-8 sequences.
        TwitterCldr::Utils::CodePoints.from_string(str)
      end

      # Returns the first sequence of fractional collation elements for an array of integer code points. Returned value
      # is an array of well formed (including weights for all significant levels) integer arrays.
      #
      # NOTE (side-effect): all used code points are removed from the input array.
      #
      def code_point_collation_elements(code_points)
        explicit_collation_elements(code_points) || implicit_collation_elements(code_points)
      end

      # Tries to build explicit collation elements array for the longest code points prefix in the given sequence. When
      # possible, combines this prefix with (not necessarily subsequent) non-starters that follow it in the sequence.
      # That's necessary because canonical ordering (that is performed during normalization) can break contractions
      # that existed in the original, de-normalized string.
      #
      # NOTE (side-effect): all used code points are removed from the input array.
      #
      # For more information see section '4.2 Produce Array' of the main algorithm at http://www.unicode.org/reports/tr10/#Main_Algorithm
      #
      def explicit_collation_elements(code_points)
        # find the longest prefix in the trie
        collation_elements, prefix_size, suffixes = @trie.find_prefix(code_points)

        return unless collation_elements

        # remove prefix from the code points sequence
        code_points.shift(prefix_size)

        non_starter_pos = 0

        used_combining_classes = {}

        while non_starter_pos < code_points.size && !suffixes.empty?
          # get next code point (possibly non-starter)
          non_starter_code_point = code_points[non_starter_pos]
          non_starter_metadata   = TwitterCldr::Shared::CodePoint.get(non_starter_code_point)

          unless non_starter_metadata
            raise UnexpectedCodePointError, "'#{non_starter_code_point}' does not appear to be a valid Unicode code point"
          end

          combining_class = non_starter_metadata.combining_class.to_i

          # code point is a starter or combining class has been already used (non-starter is 'blocked' from the prefix)
          break if combining_class == 0 || used_combining_classes[combining_class]

          used_combining_classes[combining_class] = true

          # Try to find collation elements for [prefix + non-starter] code points sequence. As the subtrie contains
          # suffixes (without prefix) we pass only non-starter itself.
          new_collation_elements, _, new_suffixes = suffixes.find_prefix([non_starter_code_point])

          if new_collation_elements
            # non-starter with a collation elements sequence corresponding to [prefix + non-starter] accepted
            collation_elements = new_collation_elements
            suffixes           = new_suffixes

            # Remove non-starter from its position in the sequence. Then we can move further from the same position.
            code_points.delete_at(non_starter_pos)
          else
            # move to the next code point
            non_starter_pos += 1
          end
        end

        collation_elements
      end

      def implicit_collation_elements(code_points)
        TwitterCldr::Collation::ImplicitCollationElements.for_code_point(code_points.shift)
      end

      class << self

        # Loads and memoizes the default fractional collation elements trie.
        #
        def default_trie
          @default_trie ||= TwitterCldr::Collation::TrieLoader.load_default_trie.lock
        end

        def tailored_trie(locale)
          tailored_tries_cache[locale]
        end

        private

        def tailored_tries_cache
          @tailored_tries_cache ||= Hash.new { |hash, locale| hash[locale] = load_tailored_trie(locale) }
        end

        def load_tailored_trie(locale)
          TwitterCldr::Collation::TrieLoader.load_tailored_trie(locale, default_trie).lock
        end

      end

    end

  end
end
