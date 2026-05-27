# frozen_string_literal: true

module RDoc
  class Markup
    # A section of table
    class Table < Element
      # Headers of each column
      #: Array[String]
      attr_accessor :header

      # Alignments of each column
      #: Array[Symbol?]
      attr_accessor :align

      # Body texts of each column
      #: Array[String]
      attr_accessor :body

      #: (Array[String], Array[Symbol?], Array[String]) -> void
      def initialize(header, align, body)
        @header, @align, @body = header, align, body
      end

      #: (Object) -> bool
      def ==(other)
        self.class == other.class && @header == other.header &&
          @align == other.align && @body == other.body
      end

      # @override
      #: (untyped) -> void
      def accept(visitor)
        visitor.accept_table(@header, @body, @align)
      end

      # @override
      #: (untyped) -> String
      def pretty_print(q)
        q.group 2, '[Table: ', ']' do
          q.group 2, '[Head: ', ']' do
            q.seplist @header.zip(@align) do |text, align|
              q.pp text
              if align
                q.text ":"
                q.breakable
                q.text align.to_s
              end
            end
          end
          q.breakable
          q.group 2, '[Body: ', ']' do
            q.seplist @body do |body|
              q.group 2, '[', ']' do
                q.seplist body do |text|
                  q.pp text
                end
              end
            end
          end
        end
      end
    end
  end
end
