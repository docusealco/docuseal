# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'singleton'

module TwitterCldr
  module Segmentation
    class Suppressions
      include Singleton

      class << self
        def instance(boundary_type, locale)
          resource_path = find_resource(boundary_type, locale)
          return NullSuppressions.instance unless resource_path

          cache[resource_path] ||= begin
            rsrc = TwitterCldr.get_resource(resource_path)

            new(
              Marshal.load(rsrc[:forwards_trie]),
              Marshal.load(rsrc[:backwards_trie])
            )
          end
        end

        private

        def find_resource(boundary_type, locale)
          path = TwitterCldr.resource_file_path(
            ['shared', 'segments', 'suppressions', locale, boundary_type]
          )

          path if TwitterCldr.resource_exists?(path)
        end

        def cache
          @cache ||= {}
        end
      end

      attr_reader :forward_trie, :backward_trie

      def initialize(forward_trie, backward_trie)
        @forward_trie = forward_trie
        @backward_trie = backward_trie
      end

      def should_break?(cursor)
        idx = cursor.position

        # consider case when a space follows the '.' (so we handle i.e. "Mr. Brown")
        idx -= 2 if cursor.codepoint(idx - 1) == 32
        node = backward_trie.root

        found = loop do
          break false if idx < 0 || idx >= cursor.length
          node = node.child(cursor.codepoint(idx))
          break false unless node
          break true if node.value
          idx -= 1
        end

        return true unless found

        node = forward_trie.root

        loop do
          return true if idx >= cursor.length
          node = node.child(cursor.codepoint(idx))
          return true unless node
          return false if node.value
          idx += 1
        end
      end
    end
  end
end
