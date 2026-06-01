# frozen_string_literal: true

module RDoc
  class Markup
    # A section of text that is added to the output document as-is
    class Raw
      # The component parts of the list
      #: Array[String]
      attr_reader :parts

      # Creates a new Raw containing +parts+
      #: (*String) -> void
      def initialize(*parts)
        @parts = parts
      end

      # Appends +text+
      #: (String) -> void
      def <<(text)
        @parts << text
      end

      #: (top) -> bool
      def ==(other) # :nodoc:
        self.class == other.class && @parts == other.parts
      end

      # Calls #accept_raw+ on +visitor+
      # @override
      #: (untyped) -> void
      def accept(visitor)
        visitor.accept_raw(self)
      end

      # Appends +other+'s parts
      #: (Raw) -> void
      def merge(other)
        @parts.concat(other.parts)
      end

      # @override
      #: (PP) -> void
      def pretty_print(q) # :nodoc:
        self.class.name =~ /.*::(\w{1,4})/i

        q.group(2, "[#{$1.downcase}: ", ']') do
          q.seplist(@parts) do |part|
            q.pp(part)
          end
        end
      end

      # Appends +texts+ onto this Paragraph
      #: (*String) -> void
      def push(*texts)
        self.parts.concat(texts)
      end

      # The raw text
      #: () -> String
      def text
        @parts.join(" ")
      end
    end
  end
end
