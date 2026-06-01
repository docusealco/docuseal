# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant `keyword_init` option for `Struct.new`.
      #
      # Since Ruby 3.2, `keyword_init` in `Struct.new` defaults to `nil` behavior.
      # Therefore, this cop detects and autocorrects redundant `keyword_init: nil`
      # and `keyword_init: true` in `Struct.new`.
      #
      # @safety
      #   This autocorrect is unsafe because when the value of `keyword_init` changes
      #   from `true` to `nil`, the return value of `Struct#keyword_init?` changes.
      #
      # @example
      #
      #   # bad
      #   Struct.new(:foo, keyword_init: nil)
      #   Struct.new(:foo, keyword_init: true)
      #
      #   # good
      #   Struct.new(:foo)
      #
      class RedundantStructKeywordInit < Base
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = 'Remove the redundant `keyword_init: %<value>s`.'
        RESTRICT_ON_SEND = %i[new].freeze

        minimum_target_ruby_version 3.2

        # @!method struct_new?(node)
        def_node_matcher :struct_new?, <<~PATTERN
          (call (const {nil? cbase} :Struct) :new ...)
        PATTERN

        # @!method keyword_init?(node)
        def_node_matcher :keyword_init?, <<~PATTERN
          {#redundant_keyword_init? #keyword_init_false?}
        PATTERN

        # @!method redundant_keyword_init?(node)
        def_node_matcher :redundant_keyword_init?, <<~PATTERN
          (pair (sym :keyword_init) {(true) (nil)})
        PATTERN

        # @!method keyword_init_false?(node)
        def_node_matcher :keyword_init_false?, <<~PATTERN
          (pair (sym :keyword_init) (false))
        PATTERN

        def on_send(node)
          return if !struct_new?(node) || node.arguments.none? || !node.last_argument.hash_type?

          keyword_init_nodes = select_keyword_init_nodes(node)
          return if keyword_init_nodes.any? { |node| keyword_init_false?(node) }

          redundant_keyword_init_nodes = select_redundant_keyword_init_nodes(keyword_init_nodes)

          redundant_keyword_init_nodes.each do |redundant_keyword_init|
            register_offense(redundant_keyword_init)
          end
        end
        alias on_csend on_send

        private

        def select_keyword_init_nodes(node)
          node.last_argument.pairs.select do |pair|
            keyword_init?(pair)
          end
        end

        def select_redundant_keyword_init_nodes(keyword_init_nodes)
          keyword_init_nodes.select do |keyword_init_node|
            redundant_keyword_init?(keyword_init_node)
          end
        end

        def register_offense(keyword_init)
          message = format(MSG, value: keyword_init.value.source)

          add_offense(keyword_init, message: message) do |corrector|
            range = range(keyword_init)

            corrector.remove(range)
          end
        end

        def range(redundant_keyword_init)
          if redundant_keyword_init.parent.left_siblings.last.is_a?(AST::Node)
            beginning_of_range = redundant_keyword_init.parent.left_siblings.last.source_range.end

            beginning_of_range.join(redundant_keyword_init.source_range.end)
          else
            redundant_keyword_init
          end
        end
      end
    end
  end
end
