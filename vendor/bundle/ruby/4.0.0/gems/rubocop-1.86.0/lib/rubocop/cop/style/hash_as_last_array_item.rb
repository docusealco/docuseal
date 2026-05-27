# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for presence or absence of braces around hash literal as a last
      # array item depending on configuration.
      #
      # NOTE: This cop will ignore arrays where multiple items are all hashes,
      # regardless of `EnforcedStyle`.
      #
      # [source,ruby]
      # ----
      # [{ one: 1 }, { two: 2 }]
      # ----
      #
      # @example EnforcedStyle: braces (default)
      #   # bad
      #   [1, 2, one: 1, two: 2]
      #
      #   # good
      #   [1, 2, { one: 1, two: 2 }]
      #
      #   # bad
      #   [one: 1, two: 2]
      #
      #   # good
      #   [{ one: 1, two: 2 }]
      #
      # @example EnforcedStyle: no_braces
      #   # bad
      #   [1, 2, { one: 1, two: 2 }]
      #
      #   # good
      #   [1, 2, one: 1, two: 2]
      #
      #   # bad
      #   [{ one: 1, two: 2 }]
      #
      #   # good
      #   [one: 1, two: 2]
      class HashAsLastArrayItem < Base
        include RangeHelp
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        def on_hash(node)
          return if node.children.first&.kwsplat_type?
          return unless (array = containing_array(node))
          return unless expected_braced_last_array_item?(array, node) && explicit_array?(array)

          if braces_style?
            check_braces(node)
          else
            check_no_braces(node)
          end
        end

        private

        def containing_array(hash_node)
          parent = hash_node.parent
          parent if parent&.array_type?
        end

        def expected_braced_last_array_item?(array, node)
          return false if array.each_value.all? do |node|
            node.hash_type? && (braces_style? ? node.braces? : !node.braces?)
          end

          !array.values[-2]&.hash_type? && array.values.last.equal?(node)
        end

        def explicit_array?(array)
          # an implicit array cannot have an "unbraced" hash
          array.square_brackets?
        end

        def check_braces(node)
          return if node.braces?

          add_offense(node, message: 'Wrap hash in `{` and `}`.') do |corrector|
            if node.single_line? || same_line?(node, node.parent)
              corrector.wrap(node, '{', '}')
            else
              indent = indent(node)
              corrector.wrap(node, "{\n#{indent}", "\n#{indent}}")
            end
          end
        end

        def check_no_braces(node)
          return unless node.braces?
          return if node.children.empty? # Empty hash cannot be "unbraced"

          add_offense(node, message: 'Omit the braces around the hash.') do |corrector|
            remove_last_element_trailing_comma(corrector, node.parent)
            corrector.remove(node.loc.begin)
            corrector.remove(node.loc.end)
          end
        end

        def braces_style?
          style == :braces
        end

        def remove_last_element_trailing_comma(corrector, node)
          range = range_with_surrounding_space(
            node.children.last.source_range,
            side: :right
          ).end.resize(1)

          corrector.remove(range) if range.source == ','
        end
      end
    end
  end
end
