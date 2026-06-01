# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Parsers
    class UnicodeRegexParser

      # This is analogous to ICU's UnicodeSet class.
      class CharacterClass < Component

        GROUPING_PAIRS = {
          close_bracket: :open_bracket
        }

        # Character classes can include set operations (eg. union, intersection, etc).
        BinaryOperator = Struct.new(:operator, :left, :right) do
          def type
            :binary_operator
          end
        end

        UnaryOperator = Struct.new(:operator, :child) do
          def type
            :unary_operator
          end
        end

        class << self

          def opening_types
            @opening_types ||= GROUPING_PAIRS.values
          end

          def closing_types
            @closing_types ||= GROUPING_PAIRS.keys
          end

          def opening_type_for(type)
            GROUPING_PAIRS[type]
          end

        end

        def initialize(root)
          @root = root
        end

        def type
          :character_class
        end

        def to_regexp_str
          set_to_regex(to_set)
        end

        def to_set
          evaluate(root)
        end

        def codepoints
          codepoints_from(root)
        end

        def to_s
          stringify(root)
        end

        def negated?
          root.type == :unary_operator && root.operator == :negate
        end

        private

        attr_reader :root

        def codepoints_from(node)
          case node
            when UnaryOperator
              codepoints_from(node.child)
            when BinaryOperator
              codepoints_from(node.left) + codepoints_from(node.right)
            else
              node.codepoints
          end
        end

        def stringify(node)
          case node
            when UnaryOperator, BinaryOperator
              op_str = case node.operator
                when :negate then '^'
                when :union, :pipe then ''
                when :dash then '-'
                when :ampersand then '&'
              end

              left = stringify(node.left)
              right = stringify(node.right)

              "#{left}#{op_str}#{right}"

            else
              node.to_s
          end
        end

        def evaluate(node)
          case node
            when UnaryOperator, BinaryOperator
              case node.operator
                when :negate
                  TwitterCldr::Shared::UnicodeRegex.valid_regexp_chars.subtract(
                    evaluate(node.child)
                  )
                when :union, :pipe
                  evaluate(node.left).union(
                    evaluate(node.right)
                  )
                when :dash
                  evaluate(node.left).difference(
                    evaluate(node.right)
                  )
                when :ampersand
                  evaluate(node.left).intersection(
                    evaluate(node.right)
                  )
              end

            else
              if node
                node.to_set
              else
                TwitterCldr::Utils::RangeSet.new([])
              end
          end
        end

      end
    end
  end
end
