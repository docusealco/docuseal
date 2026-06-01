# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared
    class Caser
      REGEX = /./

      class << self
        def upcase(string)
          string.gsub(REGEX, uppercasing_hash)
        end

        def downcase(string)
          string.gsub(REGEX, lowercasing_hash)
        end

        # toTitlecase(X): Find the word boundaries in X according
        # to Unicode Standard Annex #29, "Unicode Text Segmentation."
        # For each word boundary, find the first cased character F
        # following the word boundary. If F exists, map F to
        # Titlecase_Mapping(F); then map all characters C between F
        # and the following word boundary to Lowercase_Mapping(C).
        def titlecase(string)
          string.dup.tap do |result|
            word_iterator.each_word(result) do |_, *boundary_pair|
              if cased_pos = first_cased(string, *boundary_pair)
                result[cased_pos] = titlecasing_hash[result[cased_pos]]

                (cased_pos + 1).upto(boundary_pair.last - 1) do |pos|
                  result[pos] = lowercasing_hash[result[pos]]
                end
              end
            end
          end
        end

        private

        def first_cased(string, start_pos, end_pos)
          end_pos = string.length - 1 if end_pos >= string.length

          start_pos.upto(end_pos) do |pos|
            return pos if cased?(string[pos])
          end
        end

        def word_iterator
          @word_iterator ||= Segmentation::BreakIterator.new(:en)
        end

        def cased?(char)
          props = CodePoint.properties_for_code_point(char.ord)
          props.general_category.include?('Lt') ||
            props.uppercase || props.lowercase
        end

        def uppercasing_hash
          @uppercasing_hash ||= Hash.new do |hash, key|
            memoize_value(:simple_uppercase_map, hash, key)
          end
        end

        def lowercasing_hash
          @lowercasing_hash ||= Hash.new do |hash, key|
            memoize_value(:simple_lowercase_map, hash, key)
          end
        end

        def titlecasing_hash
          @titlecasing_hash ||= Hash.new do |hash, key|
            memoize_value(:simple_titlecase_map, hash, key)
          end
        end

        def memoize_value(field, hash, key)
          cp = TwitterCldr::Shared::CodePoint.get(key.ord)
          mapped_result = cp.send(field)
          hash[key] = mapped_result ? mapped_result : key
        end
      end
    end
  end
end
