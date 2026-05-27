# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'yaml'
require 'fileutils'

module TwitterCldr
  module Utils

    class FileSystemTrie
      VALUE_FILE = 'value.dump'

      attr_reader :path_root

      def initialize(path_root, root = Node.new)
        @path_root = path_root
        @root = root
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
        node = get_node(key)
        node && node.value
      end

      def get_node(key)
        traverse(key) do |node, key_element|
          return unless node
          node.child(key_element)
        end
      end

      # to prevent printing of a possibly huge children list in the IRB
      alias_method :inspect, :to_s

      private

      def store(key, value, override = true)
        final = store_p(key)

        if final.value.nil? || override
          final.value = value

          path = File.join(path_root, *key, VALUE_FILE)
          File.write(path, Marshal.dump(value))
        end
      end

      def store_p(key)
        current_path = path_root

        traverse(key) do |node, key_element|
          current_path = File.join(current_path, key_element)
          mkdir(current_path)
          node.child(key_element) || node.set_child(key_element, Node.new)
        end
      end

      def traverse(key)
        current_path = path_root

        key.inject(@root) do |node, key_element|
          next unless node
          next unless key_element
          current_path = File.join(current_path, key_element)
          fill_in_path(current_path, key_element, node)
          fill_in_value(current_path, key_element, node)
          yield node, key_element if block_given?
        end
      end

      def fill_in_path(current_path, key_element, parent)
        if File.exist?(current_path)
          unless parent.child(key_element)
            parent.set_child(key_element, Node.new)
          end
        end
      end

      def fill_in_value(current_path, key_element, parent)
        value_file = File.join(current_path, VALUE_FILE)
        child = parent.child(key_element)

        if File.exist?(value_file) && child && !child.value
          parent.child(key_element).value = ::Marshal.load(
            File.read(value_file)
          )
        end
      end

      def mkdir(path)
        FileUtils.mkdir_p(path) unless File.exist?(path)
      end

      class Node

        attr_accessor :value, :children

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

        def each_key_and_child(&block)
          @children.each(&block)
        end

        def keys
          @children.keys
        end

        def to_trie
          Trie.new(self.class.new(nil, @children)).lock
        end

      end
    end

  end
end
