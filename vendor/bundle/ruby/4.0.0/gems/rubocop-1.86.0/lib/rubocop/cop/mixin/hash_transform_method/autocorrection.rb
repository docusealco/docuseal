# frozen_string_literal: true

module RuboCop
  module Cop
    module HashTransformMethod
      # Internal helper class to hold autocorrect data
      Autocorrection = Struct.new(:match, :block_node, :leading, :trailing) do
        def self.from_each_with_object(node, match)
          new(match, node, 0, 0)
        end

        def self.from_hash_brackets_map(node, match)
          new(match, node.children.last, 'Hash['.length, ']'.length)
        end

        def self.from_map_to_h(node, match)
          if node.parent&.block_type? && node.parent.send_node == node
            strip_trailing_chars = 0
          else
            map_range = node.children.first.source_range
            node_range = node.source_range
            strip_trailing_chars = node_range.end_pos - map_range.end_pos
          end

          new(match, node.children.first, 0, strip_trailing_chars)
        end

        def self.from_to_h(node, match)
          new(match, node, 0, 0)
        end

        def strip_prefix_and_suffix(node, corrector)
          expression = node.source_range
          corrector.remove_leading(expression, leading)
          corrector.remove_trailing(expression, trailing)
        end

        def set_new_method_name(new_method_name, corrector)
          range = block_node.send_node.loc.selector
          if (send_end = block_node.send_node.loc.end)
            # If there are arguments (only true in the `each_with_object`
            # case)
            range = range.begin.join(send_end)
          end
          corrector.replace(range, new_method_name)
        end

        def set_new_arg_name(transformed_argname, corrector)
          corrector.replace(block_node.arguments, "|#{transformed_argname}|")
        end

        def set_new_body_expression(transforming_body_expr, corrector)
          body_source = transforming_body_expr.source
          if transforming_body_expr.hash_type? && !transforming_body_expr.braces?
            body_source = "{ #{body_source} }"
          end

          corrector.replace(block_node.body, body_source)
        end
      end
    end
  end
end
