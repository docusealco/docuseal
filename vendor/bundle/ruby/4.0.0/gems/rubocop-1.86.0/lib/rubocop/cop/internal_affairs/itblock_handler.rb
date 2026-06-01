# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks for missing `itblock` handlers. The blocks with the `it`
      # parameter introduced in Ruby 3.4 are parsed with a node type of
      # `itblock` instead of block. Cops that define `block` handlers
      # need to define `itblock` handlers or disable this cop for them.
      #
      # @example
      #
      #   # bad
      #   class BlockRelatedCop < Base
      #     def on_block(node)
      #     end
      #   end
      #
      #   # good
      #   class BlockRelatedCop < Base
      #     def on_block(node)
      #     end
      #
      #     alias on_itblock on_block
      #   end
      #
      #   class BlockRelatedCop < Base
      #     def on_block(node)
      #     end
      #
      #     alias_method :on_itblock, :on_block
      #   end
      #
      #   class BlockRelatedCop < Base
      #     def on_block(node)
      #     end
      #
      #     def on_itblock(node)
      #     end
      #   end
      class ItblockHandler < Base
        MSG = 'Define on_itblock to handle blocks with the `it` parameter.'

        def on_def(node)
          return unless block_handler?(node)
          return unless node.parent

          add_offense(node) unless itblock_handler?(node.parent)
        end

        private

        # @!method block_handler?(node)
        def_node_matcher :block_handler?, <<~PATTERN
          (def :on_block (args (arg :node)) ...)
        PATTERN

        # @!method itblock_handler?(node)
        def_node_matcher :itblock_handler?, <<~PATTERN
          {
            `(def :on_itblock (args (arg :node)) ...)
            `(alias (sym :on_itblock) (sym :on_block))
            `(send nil? :alias_method (sym :on_itblock) (sym :on_block))
          }
        PATTERN
      end
    end
  end
end
