# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Collation
    autoload :Collator,                  'twitter_cldr/collation/collator'
    autoload :ImplicitCollationElements, 'twitter_cldr/collation/implicit_collation_elements'
    autoload :SortKeyBuilder,            'twitter_cldr/collation/sort_key_builder'
    autoload :TrieBuilder,               'twitter_cldr/collation/trie_builder'
    autoload :TrieLoader,                'twitter_cldr/collation/trie_loader'
    autoload :TrieWithFallback,          'twitter_cldr/collation/trie_with_fallback'
  end
end
