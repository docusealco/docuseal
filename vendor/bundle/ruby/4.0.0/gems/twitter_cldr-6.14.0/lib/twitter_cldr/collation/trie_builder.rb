# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Collation

    # Builds a fractional collation elements Trie from the file containing a fractional collation elements table.
    #
    module TrieBuilder

      COLLATION_ELEMENT_REGEXP = /^((?:[0-9A-F]+)(?:\s[0-9A-F]+)*);\s((?:\[.*?\])(?:\[.*?\])*)/

      FRACTIONAL_UCA_SHORT_PATH = File.join(TwitterCldr::RESOURCES_DIR, 'collation', 'FractionalUCA_SHORT.txt')

      class << self

        def load_default_trie
          File.open(FRACTIONAL_UCA_SHORT_PATH, 'r') { |table| parse_collation_elements_table(table) }
        end

        def load_tailored_trie(locale, fallback)
          build_tailored_trie(tailoring_data(locale), fallback)
        end

        def tailoring_data(locale)
          TwitterCldr.get_resource(:collation, :tailoring, locale)
        end

        private

        def parse_collation_elements_table(table, trie = TwitterCldr::Utils::Trie.new)
          table.each_line do |line|
            trie.set(parse_code_points($1), parse_collation_element($2)) if COLLATION_ELEMENT_REGEXP =~ line
          end

          trie
        end

        def parse_code_points(string)
          string.split.map(&:hex)
        end

        def parse_collation_element(string)
          string.scan(/\[.*?\]/).map do |match|
            match[1..-2].gsub(/\s/, '').split(',', -1).map { |bytes| bytes.hex }
          end
        end

        def build_tailored_trie(tailoring_data, fallback)
          trie = TwitterCldr::Collation::TrieWithFallback.new(fallback)

          parse_collation_elements_table(tailoring_data[:tailored_table], trie)
          copy_expansions(trie, fallback, parse_suppressed_starters(tailoring_data[:suppressed_contractions]))

          trie
        end

        def copy_expansions(trie, source_trie, suppressed_starters)
          suppressed_starters.each do |starter|
            trie.add([starter], source_trie.get([starter]))
          end

          (trie.starters - suppressed_starters).each do |starter|
            source_trie.each_starting_with(starter) do |key, value|
              trie.add(key, value)
            end
          end
        end

        def parse_suppressed_starters(suppressed_contractions)
          suppressed_contractions.chars.map do |starter|
            TwitterCldr::Utils::CodePoints.from_string(starter).first
          end
        end

      end

    end

  end
end
