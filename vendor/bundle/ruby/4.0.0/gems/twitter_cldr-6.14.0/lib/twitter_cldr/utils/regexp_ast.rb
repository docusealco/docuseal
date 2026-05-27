# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'base64'

module TwitterCldr
  module Utils
    module RegexpAst

      def self.load(ast_str)
        Marshal.load(Base64.decode64(ast_str))
      end

      def self.dump(ast)
        Base64.encode64(Marshal.dump(ast))
      end

      class Node
        attr_reader :expressions, :quantifier

        def initialize(expressions, quantifier)
          @expressions = expressions
          @quantifier = quantifier
        end

        def quantified?
          !!quantifier
        end

        def self.from_parser_node(node, expressions)
          new(expressions, Quantifier.from_parser_node(node))
        end
      end

      class CharacterSet < Node
        attr_reader :members, :negated
        alias :negated? :negated

        def initialize(expressions, quantifier, members, negated)
          @members = members; @negated = negated
          super(expressions, quantifier)
        end

        def self.from_parser_node(node, expressions)
          new(
            expressions, Quantifier.from_parser_node(node),
            fix_members(node.members), node.negative?
          )
        end

        private

        # CLDR occasionally uses \d and other escapes in character classes
        # to signify 0-9 and friends. This is legal regex syntax, but the
        # regexp_parser gem doesn't handle it correctly, so we have to
        # repair things here.
        def self.fix_members(members)
          members.join.scan(/(\\[wd]|\w-\w|\w|-)/).to_a.flatten.inject([]) do |ret, member|
            case member
              when '\d' then ret << '0-9'
              when '\w' then ret += ['A-Z', 'a-z', '0-9', '_']
              else ret << member
            end

            ret
          end
        end
      end

      class Literal < Node
        attr_reader :text

        def initialize(expressions, quantifier, text)
          @text = text
          super(expressions, quantifier)
        end

        def self.from_parser_node(node, expressions)
          new(
            expressions, Quantifier.from_parser_node(node), node.text
          )
        end
      end

      class Quantifier
        attr_reader :max, :min

        def initialize(max, min)
          @max = max; @min = min
        end

        def self.from_parser_node(node)
          if node.quantifier
            new(
              node.quantifier.max,
              node.quantifier.min
            )
          end
        end
      end

      class EscapeSequence < Literal; end
      class Word < Node; end
      class Digit < Node; end
      class Sequence < Node; end
      class Alternation < Node; end
      class Alternative < Node; end
      class Capture < Node; end
      class Passive < Node; end
      class Root < Node; end
      class BeginningOfLine < Node; end
      class EndOfLine < Node; end
      class WordBoundary < Node; end

    end
  end
end
