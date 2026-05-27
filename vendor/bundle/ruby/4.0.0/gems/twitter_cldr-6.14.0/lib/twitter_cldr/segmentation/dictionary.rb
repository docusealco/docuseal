# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class Dictionary

      class << self
        def burmese
          get('burmese')
        end

        def cj
          get('cj')
        end

        def khmer
          get('khmer')
        end

        def lao
          get('lao')
        end

        def thai
          get('thai')
        end

        def get(name)
          dictionary_cache[name] ||= begin
            resource = TwitterCldr.get_resource(
              'shared', 'segments', 'dictionaries', "#{name}dict.dump"
            )

            new(resource)
          end
        end

        private

        def dictionary_cache
          @dictionary_cache ||= {}
        end
      end

      attr_reader :trie

      def initialize(trie)
        @trie = trie
      end

      def matches(cursor, max_search_length, limit)
        return 0 if cursor.length == 0

        count = 0
        num_chars = 1
        current = trie.root.child(cursor.codepoint)
        values = []
        lengths = []

        until current.nil?
          if current.has_value? && count < limit
            values << current.value
            lengths << num_chars
            count += 1
          end

          break if num_chars >= max_search_length

          current = current.child(
            cursor.codepoint(cursor.position + num_chars)
          )

          num_chars += 1
        end

        [count, values, lengths, num_chars]
      end

    end
  end
end
