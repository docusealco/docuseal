# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Collation

    # Builds a fractional collation elements Trie from the file containing a fractional collation elements table.
    #
    module TrieLoader

      DUMPS_DIR = File.join(TwitterCldr::RESOURCES_DIR, 'collation', 'tries')

      DEFAULT_TRIE_LOCALE = :default

      class << self

        def load_default_trie
          load_trie
        end

        def load_tailored_trie(locale, fallback)
          trie = load_trie(locale)
          trie.fallback = fallback
          trie
        end

        def dump_path(locale)
          File.join(DUMPS_DIR, "#{locale}.dump")
        end

        private

        def load_trie(locale = DEFAULT_TRIE_LOCALE)
          load_dump(locale) do |dump|
            Marshal.load(dump)
          end
        end

        def load_dump(locale, &block)
          File.open(dump_path(locale), 'r', &block)
        end

      end

    end

  end
end