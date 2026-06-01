# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Utils

    # This class represents a trie - a tree data structure, also known as a prefix tree.
    #
    # Every node corresponds to a single character of the key. To find the value by key one goes down the trie
    # starting from the root and descending one character at a time. If at some level current node doesn't have a
    # child corresponding to the next character of the key, then the trie doesn't contain a value with the given key.
    # Otherwise, the final node, corresponding to the last character of the key, should contain the value. If it's
    # nil, then the trie doesn't contain a value with the given key (or the value itself is nil).
    #
    class Trie
      attr_reader :root

      # Initializes a new trie. If `trie_hash` value is passed it's used as the initial data for the trie. Usually,
      # `trie_hash` is extracted from other trie and represents its subtrie.
      #
      def initialize(root = Node.new)
        @root = root
        @locked = false
      end

      def lock
        @locked = true
        self
      end

      def locked?
        @locked
      end

      def starters
        @root.keys
      end

      def each_starting_with(starter, &block)
        starting_node = @root.child(starter)
        each_pair(starting_node, [starter], &block) if starting_node
      end

      def empty?
        !@root.has_children?
      end

      def add(key, value)
        store(key, value, false)
      end

      def set(key, value)
        store(key, value)
      end

      def get(key)
        final = key.inject(@root) do |node, key_element|
          return unless node
          node.child(key_element)
        end

        final && final.value
      end

      # Finds the longest substring of the `key` that matches, as a key, a node in the trie.
      #
      # Returns a three elements array:
      #
      #   1. value in the last node that was visited and has non-nil value
      #   2. size of the `key` prefix that matches this node
      #   3. subtrie for which that node is a root
      #
      def find_prefix(key)
        last_prefix_size = 0
        last_with_value  = @root

        key.each_with_index.inject(@root) do |node, (key_element, index)|
          child = node.child(key_element)

          break unless child

          if child.value
            last_prefix_size = index + 1
            last_with_value  = child
          end

          child
        end

        [last_with_value.value, last_prefix_size, last_with_value.to_trie]
      end

      def marshal_dump
        @root
      end

      def marshal_load(root)
        @root = root
      end

      def to_hash
        @root.subtrie_hash
      end

      alias inspect to_s # to prevent printing of a possibly huge children list in the IRB

      private

      def store(key, value, override = true)
        raise RuntimeError, "can't store value in a locked trie" if locked?

        final = key.inject(@root) do |node, key_element|
          node.child(key_element) || node.set_child(key_element, Node.new)
        end

        final.value = value unless final.value && !override
      end

      def each_pair(node, key, &block)
        yield [key, node.value] if node.value

        node.each_key_and_child do |key_element, child|
          each_pair(child, key + [key_element], &block)
        end
      end

      class Node

        attr_accessor :value

        def initialize(value = nil, children = {})
          @value    = value
          @children = children
        end

        def child(key)
          @children[key]
        end

        def set_child(key, child)
          @children[key] = child
        end

        def has_children?
          !@children.empty?
        end

        def has_value?
          !!value
        end

        def each_key_and_child(&block)
          @children.each(&block)
        end

        def keys
          @children.keys
        end

        def to_trie
          Trie.new(self.class.new(nil, @children)).lock
        end

        def subtrie_hash
          @children.inject({}) do |memo, (key, child)|
            memo[key] = [child.value, child.subtrie_hash]
            memo
          end
        end

      end

    end

  end
end
