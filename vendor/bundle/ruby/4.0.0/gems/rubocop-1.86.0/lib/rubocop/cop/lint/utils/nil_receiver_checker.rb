# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      module Utils
        # Utility class that checks if the receiver can't be nil.
        class NilReceiverChecker
          NIL_METHODS = (nil.methods + %i[!]).to_set.freeze

          def initialize(receiver, additional_nil_methods)
            @receiver = receiver
            @additional_nil_methods = additional_nil_methods
            @checked_nodes = {}.compare_by_identity
          end

          def cant_be_nil?
            sole_condition_of_parent_if?(@receiver) || _cant_be_nil?(@receiver.parent, @receiver)
          end

          private

          # rubocop:disable Metrics
          def _cant_be_nil?(node, receiver)
            return false unless node

            # For some nodes, we check their parent and then some children for these parents.
            # This is added to avoid infinite loops.
            return false if @checked_nodes.key?(node)

            @checked_nodes[node] = true

            case node.type
            when :def, :defs, :class, :module, :sclass
              return false
            when :send
              return non_nil_method?(node.method_name) if node.receiver == receiver

              node.arguments.each do |argument|
                return true if _cant_be_nil?(argument, receiver)
              end

              return true if _cant_be_nil?(node.receiver, receiver)
            when :begin
              return true if _cant_be_nil?(node.children.first, receiver)
            when :if, :case
              return true if _cant_be_nil?(node.condition, receiver)
            when :and, :or
              return true if _cant_be_nil?(node.lhs, receiver)
            when :pair
              if _cant_be_nil?(node.key, receiver) ||
                 _cant_be_nil?(node.value, receiver)
                return true
              end
            when :when
              node.conditions.each do |condition|
                return true if _cant_be_nil?(condition, receiver)
              end
            when :lvasgn, :ivasgn, :cvasgn, :gvasgn, :casgn
              return true if _cant_be_nil?(node.expression, receiver)
            end

            # Due to how `if/else` are implemented (`elsif` is a child of `if` or another `elsif`),
            # using left_siblings will not work correctly for them.
            if !else_branch?(node) || (node.if_type? && !node.elsif?)
              node.left_siblings.reverse_each do |sibling|
                next unless sibling.is_a?(AST::Node)

                return true if _cant_be_nil?(sibling, receiver)
              end
            end

            if node.parent
              _cant_be_nil?(node.parent, receiver)
            else
              false
            end
          end
          # rubocop:enable Metrics

          def non_nil_method?(method_name)
            !NIL_METHODS.include?(method_name) && !@additional_nil_methods.include?(method_name)
          end

          # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          def sole_condition_of_parent_if?(node)
            parent = node.parent

            while parent
              if parent.if_type?
                condition = parent.condition
                if condition == node || (condition.csend_type? && !condition.receiver.equal?(node))
                  return true
                end

                parent = find_top_if(parent) if parent.elsif?
              elsif else_branch?(parent)
                # Find the top `if` for `else`.
                parent = parent.parent
              end

              parent = parent&.parent
            end

            false
          end
          # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

          def else_branch?(node)
            node.parent&.if_type? && node.parent.else_branch == node
          end

          def find_top_if(node)
            node = node.parent while node.elsif?

            node
          end
        end
      end
    end
  end
end
