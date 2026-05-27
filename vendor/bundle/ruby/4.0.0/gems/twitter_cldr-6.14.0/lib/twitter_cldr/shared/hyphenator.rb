# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

# Documentation: https://github.com/hunspell/hyphen/blob/21127cc8493a68d4fe9adbb71377b469b4f2b550/doc/tb87nemeth.pdf

module TwitterCldr
  module Shared
    class Hyphenator
      class UnsupportedLocaleError < StandardError; end

      BASE_RESOURCE_PATH = %w(shared hyphenation).freeze
      DEFAULT_LEFT_HYPHEN_MIN = 2
      DEFAULT_RIGHT_HYPHEN_MIN = 2
      DEFAULT_NO_HYPHEN = "-'’".freeze

      class << self
        def get(locale)
          locale = find_supported_locale(locale)

          unless locale
            raise UnsupportedLocaleError,
              "'#{locale}' is not a supported hyphenation locale"
          end

          cache[locale] ||= begin
            resource = resource_for(locale)
            new(resource[:rules], locale, resource[:options])
          end
        end

        def supported_locale?(locale)
          !!find_supported_locale(locale)
        end

        def supported_locales
          @supported_locales ||= begin
            absolute_resource_path = TwitterCldr.absolute_resource_path(
              File.join(BASE_RESOURCE_PATH)
            )

            files = Dir.glob(File.join(absolute_resource_path, '*.yml'))
            files.map { |f| File.basename(f).chomp('.yml') }
          end
        end

        private

        def find_supported_locale(locale)
          maximized_locale = Locale.parse(locale.to_s).maximize

          maximized_locale.permutations('-').find do |locale_candidate|
            TwitterCldr.resource_exists?(
              *BASE_RESOURCE_PATH, locale_candidate
            )
          end
        end

        def cache
          @cache ||= {}
        end

        def resource_for(locale)
          TwitterCldr.get_resource(*BASE_RESOURCE_PATH, locale)
        end
      end

      attr_reader :rules, :locale, :options, :trie

      def initialize(rules, locale, options)
        @rules = rules
        @locale = locale
        @options = options
        @trie = build_trie_from(rules)
      end

      # 0x00AD is a soft hyphen
      def hyphenate(text, hyphen = "\u00AD")
        each_chunk(text).to_a.join(hyphen)
      end

      def each_chunk(text)
        if block_given?
          last_pos = 0

          each_position(text) do |pos|
            yield text[last_pos...pos].tap { last_pos = pos }
          end

          if last_pos < text.size
            yield text[last_pos..text.size]
          end
        else
          to_enum(__method__, text)
        end
      end

      def each_position(text)
        if block_given?
          text = ".#{text}."
          break_weights = break_weights_for(text)

          left = left_hyphen_min
          right = text.size - right_hyphen_min - 2

          (left...right).each do |idx|
            yield idx if break_weights[idx].odd?
          end
        else
          to_enum(__method__, text)
        end
      end

      private

      def break_weights_for(text)
        break_weights = Array.new(text.size - 1, 0)

        text.each_char.with_index do |char, idx|
          subtrie = trie.root
          counter = idx

          while subtrie
            subtrie = subtrie.child(text[counter])
            counter += 1

            if subtrie && subtrie.has_value?
              update_break_weights(subtrie.value, break_weights, idx)
            end
          end
        end

        remove_illegal_hyphens(break_weights, text)
      end

      def update_break_weights(pattern, break_weights, start_idx)
        pattern_idx = 0

        pattern.each_char do |segment|
          if segment =~ /\d/
            int_seg = segment.to_i
            idx = (start_idx + pattern_idx) - 1
            break if idx >= break_weights.size

            break_weights[idx] = if break_weights[idx] > int_seg
              break_weights[idx]
            else
              int_seg
            end
          else
            pattern_idx += 1
          end
        end
      end

      def remove_illegal_hyphens(break_weights, text)
        break_weights.map.with_index do |break_weight, idx|
          next break_weight if idx.zero?
          next 0 if no_hyphen.include?(text[idx - 1])
          break_weight
        end
      end

      def left_hyphen_min
        @left_hyphen_min ||=
          options.fetch(:lefthyphenmin, DEFAULT_LEFT_HYPHEN_MIN).to_i
      end

      def right_hyphen_min
        @right_hyphen_min ||=
          options.fetch(:righthyphenmin, DEFAULT_RIGHT_HYPHEN_MIN).to_i
      end

      def no_hyphen
        @no_hyphen ||= options.fetch(:nohyphen, DEFAULT_NO_HYPHEN)
      end

      def build_trie_from(rules)
        TwitterCldr::Utils::Trie.new.tap do |trie|
          rules.each do |rule|
            trie.add(rule.gsub(/\d/, '').each_char, rule)
          end
        end
      end
    end
  end
end
