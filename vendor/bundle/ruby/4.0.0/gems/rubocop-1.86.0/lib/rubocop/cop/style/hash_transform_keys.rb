# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for uses of `+_.each_with_object({}) {...}+`,
      # `+_.map {...}.to_h+`, and `+Hash[_.map {...}]+` that are actually just
      # transforming the keys of a hash, and tries to use a simpler & faster
      # call to `transform_keys` instead.
      # It should only be enabled on Ruby version 2.5 or newer.
      # (`transform_keys` was added in Ruby 2.5.)
      #
      # @safety
      #   This cop identifies the receiver as a hash by checking for literal hash
      #   syntax and common methods that are known to return hashes (e.g. `to_h`,
      #   `merge`, `invert`, `group_by`, etc.). However, it is unsafe because it
      #   is possible for a custom class to define one of these methods and return
      #   something other than a hash.
      #
      # @example
      #   # bad
      #   {a: 1, b: 2}.each_with_object({}) { |(k, v), h| h[foo(k)] = v }
      #   Hash[{a: 1, b: 2}.collect { |k, v| [foo(k), v] }]
      #   {a: 1, b: 2}.map { |k, v| [k.to_s, v] }.to_h
      #   {a: 1, b: 2}.to_h { |k, v| [k.to_s, v] }
      #   foo.to_h.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }
      #   foo.merge(bar).map { |k, v| [k.to_s, v] }.to_h
      #
      #   # good
      #   {a: 1, b: 2}.transform_keys { |k| foo(k) }
      #   {a: 1, b: 2}.transform_keys { |k| k.to_s }
      #   foo.to_h.transform_keys { |k| k.to_sym }
      #   foo.merge(bar).transform_keys { |k| k.to_s }
      #
      #   # Won't register an offense - receiver is not known to be a hash
      #   foo.bar.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
      #   baz.map { |k, v| [k.to_s, v] }.to_h
      class HashTransformKeys < Base
        include HashTransformMethod
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.5

        # @!method on_bad_each_with_object(node)
        def_node_matcher :on_bad_each_with_object, <<~PATTERN
          (block
            (call #hash_receiver? :each_with_object (hash))
            (args
              (mlhs
                (arg $_)
                (arg _val))
              (arg _memo))
            (call (lvar _memo) :[]= $!`_memo $(lvar _val)))
        PATTERN

        # @!method on_bad_hash_brackets_map(node)
        def_node_matcher :on_bad_hash_brackets_map, <<~PATTERN
          (send
            (const _ :Hash)
            :[]
            (block
              (call #hash_receiver? {:map :collect})
              (args
                (arg $_)
                (arg _val))
              (array $_ $(lvar _val))))
        PATTERN

        # @!method on_bad_map_to_h(node)
        def_node_matcher :on_bad_map_to_h, <<~PATTERN
          (call
            (block
              (call #hash_receiver? {:map :collect})
              (args
                (arg $_)
                (arg _val))
              (array $_ $(lvar _val)))
            :to_h)
        PATTERN

        # @!method on_bad_to_h(node)
        def_node_matcher :on_bad_to_h, <<~PATTERN
          (block
            (call #hash_receiver? :to_h)
            (args
              (arg $_)
              (arg _val))
            (array $_ $(lvar _val)))
        PATTERN

        private

        def extract_captures(match)
          key_argname, key_body_expr, val_body_expr = *match
          Captures.new(key_argname, key_body_expr, val_body_expr)
        end

        def new_method_name
          'transform_keys'
        end
      end
    end
  end
end
