# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking gem declarations.
    module GemspecHelp
      extend NodePattern::Macros

      # @!method gem_specification?(node)
      def_node_matcher :gem_specification?, <<~PATTERN
        (block
          (send
            (const
              (const {cbase nil?} :Gem) :Specification) :new)
          (args
            (arg $_)) ...)
      PATTERN

      # @!method gem_specification(node)
      def_node_search :gem_specification, <<~PATTERN
        (block
          (send
            (const
              (const {cbase nil?} :Gem) :Specification) :new)
          (args
            (arg $_)) ...)
      PATTERN

      # @!method assignment_method_declarations(node)
      def_node_search :assignment_method_declarations, <<~PATTERN
        (send
          (lvar {#match_block_variable_name? :_1 :it}) _ ...)
      PATTERN

      # @!method indexed_assignment_method_declarations(node)
      def_node_search :indexed_assignment_method_declarations, <<~PATTERN
        (send
          (send (lvar {#match_block_variable_name? :_1 :it}) _)
          :[]=
          literal?
          _
        )
      PATTERN

      def match_block_variable_name?(receiver_name)
        gem_specification(processed_source.ast) do |block_variable_name|
          return block_variable_name == receiver_name
        end
      end
    end
  end
end
