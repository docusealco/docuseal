# frozen_string_literal: true

module RDoc
  class Markup
    # Base class defining the interface for all markup elements found in documentation
    # @abstract
    class Element
      # @abstract
      #: (untyped) -> void
      def accept(visitor)
        raise NotImplementedError, "#{self.class} must implement the accept method"
      end

      # @abstract
      #: (PP) -> void
      def pretty_print(q)
        raise NotImplementedError, "#{self.class} must implement the pretty_print method"
      end
    end
  end
end
