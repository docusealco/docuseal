# frozen_string_literal: true

module RDoc
  class Markup
    # A hard-break in the middle of a paragraph.
    class HardBreak < Element
      @instance = new

      # RDoc::Markup::HardBreak is a singleton
      #: () -> HardBreak
      def self.new
        @instance
      end

      # Calls #accept_hard_break on +visitor+
      # @override
      #: (untyped) -> void
      def accept(visitor)
        visitor.accept_hard_break(self)
      end

      #: (top) -> bool
      def ==(other) # :nodoc:
        self.class === other
      end

      # @override
      #: (PP) -> void
      def pretty_print(q) # :nodoc:
        q.text("[break]")
      end
    end
  end
end
