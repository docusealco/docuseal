# frozen_string_literal: true

module RDoc
  class Markup
    # An empty line
    class BlankLine < Element
      @instance = new

      # RDoc::Markup::BlankLine is a singleton
      #: () -> BlankLine
      def self.new
        @instance
      end

      # Calls #accept_blank_line on +visitor+
      # @override
      #: (untyped) -> void
      def accept(visitor)
        visitor.accept_blank_line(self)
      end

      # @override
      #: (PP) -> void
      def pretty_print(q) # :nodoc:
        q.text("blankline")
      end
    end
  end
end
