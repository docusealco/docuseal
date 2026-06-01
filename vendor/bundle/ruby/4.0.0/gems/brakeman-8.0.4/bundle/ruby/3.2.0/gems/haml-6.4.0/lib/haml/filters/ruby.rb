# frozen_string_literal: true
module Haml
  class Filters
    class Ruby < Base
      def compile(node)
        [:multi, [:newline], [:code, node.value[:text]]]
      end
    end
  end
end
