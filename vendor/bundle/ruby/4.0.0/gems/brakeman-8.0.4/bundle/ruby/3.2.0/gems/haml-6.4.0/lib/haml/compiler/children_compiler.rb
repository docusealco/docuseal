# frozen_string_literal: true
require 'haml/temple_line_counter'

module Haml
  class Compiler
    class ChildrenCompiler
      def initialize
        @lineno = 1
        @multi_flattener = Temple::Filters::MultiFlattener.new
      end

      def compile(node, &block)
        temple = [:multi]
        return temple if node.children.empty?

        temple << [:whitespace] if prepend_whitespace?(node)
        node.children.each do |n|
          rstrip_whitespace!(temple) if nuke_prev_whitespace?(n)
          insert_newlines!(temple, n)
          temple << moving_lineno(n) { block.call(n) }
          temple << [:whitespace] if insert_whitespace?(n)
        end
        rstrip_whitespace!(temple) if nuke_inner_whitespace?(node)
        temple
      end

      private

      def insert_newlines!(temple, node)
        (node.line - @lineno).times do
          temple << [:newline]
        end

        @lineno = node.line
      end

      def moving_lineno(node, &block)
        # before: As they may have children, we need to increment lineno before compilation.
        case node.type
        when :script, :silent_script
          @lineno += 1
        when :tag
          [node.value[:dynamic_attributes].new, node.value[:dynamic_attributes].old].compact.each do |attribute_hash|
            @lineno += attribute_hash.count("\n")
          end
          @lineno += 1 if node.children.empty? && node.value[:parse]
        end

        temple = block.call # compile

        # after: filter may not have children, and for some dynamic filters we can't predict the number of lines.
        case node.type
        when :filter
          @lineno += TempleLineCounter.count_lines(temple)
        end

        temple
      end

      def prepend_whitespace?(node)
        return false unless %i[comment tag].include?(node.type)
        !nuke_inner_whitespace?(node)
      end

      def nuke_inner_whitespace?(node)
        case
        when node.type == :tag
          node.value[:nuke_inner_whitespace]
        when node.parent.nil?
          false
        else
          nuke_inner_whitespace?(node.parent)
        end
      end

      def nuke_prev_whitespace?(node)
        case node.type
        when :tag
          node.value[:nuke_outer_whitespace]
        when :silent_script
          !node.children.empty? && nuke_prev_whitespace?(node.children.first)
        else
          false
        end
      end

      def nuke_outer_whitespace?(node)
        return false if node.type != :tag
        node.value[:nuke_outer_whitespace]
      end

      def rstrip_whitespace!(temple)
        return if temple.size == 1

        case temple[0]
        when :multi
          case temple[-1][0]
          when :whitespace
            temple.delete_at(-1)
          when :multi, :block
            rstrip_whitespace!(temple[-1])
          end
        when :block
          _block, code, exp = temple
          if code.start_with?(/\s*if\s/)
            # Remove [:whitespace] before `end`
            exp.replace(@multi_flattener.call(exp))
            rstrip_whitespace!(exp)

            # Remove [:whitespace] before `else` if exists
            else_index = find_else_index(exp)
            if else_index
              whitespace_index = else_index - 1
              while exp[whitespace_index] == [:newline]
                whitespace_index -= 1
              end
              if exp[whitespace_index] == [:whitespace]
                exp.delete_at(whitespace_index)
              end
            end
          end
        end
      end

      def find_else_index(temple)
        multi, *args = temple
        return nil if multi != :multi

        args.each_with_index do |arg, index|
          if arg[0] == :code && arg[1].match?(/\A\s*else\s*\z/)
            return index + 1
          end
        end
        nil
      end

      def insert_whitespace?(node)
        return false if nuke_outer_whitespace?(node)

        case node.type
        when :doctype
          node.value[:type] != 'xml'
        when :comment, :plain, :tag
          true
        when :script
          node.children.empty? && !nuke_inner_whitespace?(node)
        when :filter
          !%w[ruby].include?(node.value[:name])
        else
          false
        end
      end
    end
  end
end
