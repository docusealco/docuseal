# frozen_string_literal: true
module Haml
  class Filters
    class Escaped < Base
      def compile(node)
        text = node.value[:text].rstrip
        temple = compile_text(text)
        [:escape, true, temple]
      end

      private

      def compile_text(text)
        if ::Haml::Util.contains_interpolation?(text)
          [:dynamic, ::Haml::Util.unescape_interpolation(text)]
        else
          [:static, text]
        end
      end
    end
  end
end
