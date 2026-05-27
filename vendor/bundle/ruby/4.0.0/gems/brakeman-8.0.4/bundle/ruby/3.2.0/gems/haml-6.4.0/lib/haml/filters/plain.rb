# frozen_string_literal: true
require 'haml/string_splitter'

module Haml
  class Filters
    class Plain < Base
      def compile(node)
        text = node.value[:text]
        text = text.rstrip unless ::Haml::Util.contains_interpolation?(text) # for compatibility
        [:multi, [:newline], *compile_plain(text)]
      end

      private

      def compile_plain(text)
        string_literal = ::Haml::Util.unescape_interpolation(text)
        StringSplitter.compile(string_literal).map do |temple|
          type, str = temple
          case type
          when :dynamic
            [:escape, false, [:dynamic, str]]
          else
            temple
          end
        end
      end
    end
  end
end
