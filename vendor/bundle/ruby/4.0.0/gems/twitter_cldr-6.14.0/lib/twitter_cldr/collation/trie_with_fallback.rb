# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Collation

    # Trie that delegates all not found keys to the fallback.
    #
    # Note: methods #get and #find_prefix have a bit different behavior. The first one, #get, delegates to the fallback
    # any key that was not found. On the other hand, #find_refix delegates the key only if none of its prefixes was
    # found.
    #
    # E.g., if the fallback contains key [1, 2] with value '12' and the trie itself contains only key [1] with value '1'
    # results will be the following:
    #
    #   trie.get([1, 2]) #=> '12' - key [1, 2] wasn't found in the trie, so it was delegated to the fallback where the
    #                               value '12' was found.
    #
    #   trie.find_prefix([1, 2]) #=> ['1', 1, suffixes] - key [1, 2] is not present in the trie, but its prefix [1] was
    #                                                     found, so the fallback wasn't used.
    #
    #   trie.find_prefix([3, 2]) - the trie itself includes neither key [3, 2] nor its prefix [3], so this call is
    #                              delegated to the fallback.
    #
    # This special behavior of the #find_prefix method allows 'hiding' fallback keys that contain more than one element
    # by adding their one element prefixes to the trie itself. This feature is useful for some applications, e.g., for
    # suppressing contractions in a tailored fractional collation elements trie.
    #
    class TrieWithFallback < TwitterCldr::Utils::Trie

      attr_accessor :fallback

      def initialize(fallback)
        super()
        self.fallback = fallback
      end

      def get(key)
        super || fallback.get(key)
      end

      def find_prefix(key)
        value, prefix_size, suffixes = super

        if prefix_size > 0
          [value, prefix_size, suffixes]
        else
          fallback.find_prefix(key)
        end
      end

    end

  end
end
