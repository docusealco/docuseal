# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'regexp_parser'

module TwitterCldr
  module Resources

    class RegexpAstGenerator
      class << self

        def generate(regexp_str)
          tree = Regexp::Parser.parse(regexp_str)
          walk(tree)
        end

        private

        def walk(node)
          expressions = if node.respond_to?(:expressions)
            node.expressions.map { |expr| walk(expr) }
          else
            []
          end

          class_for(node).from_parser_node(node, expressions)
        end

        def class_for(klass)
          TwitterCldr::Utils::RegexpAst.const_get(
            klass.class.to_s.split("::").last.to_sym
          )
        end

      end
    end

  end
end
