# frozen_string_literal: true
module Haml
  class Compiler
    class CommentCompiler
      def compile(node, &block)
        if node.value[:conditional]
          compile_conditional_comment(node, &block)
        else
          compile_html_comment(node, &block)
        end
      end

      private

      def compile_html_comment(node, &block)
        if node.children.empty?
          [:html, :comment, compile_text(node)]
        else
          [:html, :comment, yield(node)]
        end
      end

      def compile_conditional_comment(node, &block)
        condition = node.value[:conditional]
        if node.value[:conditional] =~ /\A\[(\[*[^\[\]]+\]*)\]/
          condition = $1
        end

        content =
          if node.children.empty?
            compile_text(node)
          else
            yield(node)
          end
        [:html, :condcomment, condition, content, node.value[:revealed]]
      end

      def compile_text(node)
        text =
          if node.value[:parse]
            # Just always escaping the result for safety. We could respect
            # escape_html, but I don't see any use case for it.
            [:escape, true, [:dynamic, node.value[:text]]]
          else
            [:static, node.value[:text]]
          end
        [:multi, [:static, ' '], text, [:static, ' ']]
      end
    end
  end
end
