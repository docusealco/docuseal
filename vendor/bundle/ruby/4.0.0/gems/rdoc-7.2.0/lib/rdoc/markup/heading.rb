# frozen_string_literal: true

module RDoc
  class Markup
    # IMPORTANT! This weird workaround is required to ensure that RDoc can correctly deserializing Marshal data from
    # older rubies. Older rubies have `Heading` as a struct, so if we change it to a class, deserialization fails
    if RUBY_VERSION.start_with?("4.")
      class Heading < Element
        #: String
        attr_reader :text

        #: Integer
        attr_accessor :level

        #: (Integer, String) -> void
        def initialize(level, text)
          super()

          @level = level
          @text = text
        end

        #: (Object) -> bool
        def ==(other)
          other.is_a?(Heading) && other.level == @level && other.text == @text
        end
      end
    else
      Heading = Struct.new(:level, :text)
    end

    # A heading with a level (1-6) and text
    #
    #  RDoc syntax:
    #   = Heading 1
    #   == Heading 2
    #   === Heading 3
    #
    #  Markdown syntax:
    #   # Heading 1
    #   ## Heading 2
    #   ### Heading 3
    #
    class Heading
      # A singleton RDoc::Markup::ToLabel formatter for headings.
      #: () -> RDoc::Markup::ToLabel
      def self.to_label
        @to_label ||= Markup::ToLabel.new
      end

      # A singleton plain HTML formatter for headings. Used for creating labels for the Table of Contents
      #: () -> RDoc::Markup::ToHtml
      def self.to_html
        @to_html ||= begin
          markup = Markup.new
          markup.add_regexp_handling CrossReference::CROSSREF_REGEXP, :CROSSREF

          to_html = Markup::ToHtml.new nil

          def to_html.handle_regexp_CROSSREF(text)
            text.sub(/^\\/, '')
          end

          to_html
        end
      end

      # @override
      #: (untyped) -> void
      def accept(visitor)
        visitor.accept_heading(self)
      end

      # An HTML-safe anchor reference for this header using GitHub-style formatting:
      # - Lowercase
      # - Spaces converted to hyphens
      # - Special characters removed (except hyphens)
      #
      # Examples:
      #   "Hello"       -> "hello"
      #   "Hello World" -> "hello-world"
      #   "Foo Bar Baz" -> "foo-bar-baz"
      #
      #: () -> String
      def aref
        self.class.to_label.convert text.dup
      end

      # An HTML-safe anchor reference using legacy RDoc formatting:
      # - Prefixed with "label-"
      # - Original case preserved
      # - Spaces converted to + (URL encoding style)
      # - Special characters percent-encoded
      #
      # Returns nil if it would be the same as the GitHub-style aref (no alias needed).
      #
      # Examples:
      #   "hello"       -> "label-hello" (different due to label- prefix)
      #   "Hello"       -> "label-Hello"
      #   "Hello World" -> "label-Hello+World"
      #   "Foo Bar Baz" -> "label-Foo+Bar+Baz"
      #
      #: () -> String?
      def legacy_aref
        "label-#{self.class.to_label.convert_legacy text.dup}"
      end

      # Creates a fully-qualified label (GitHub-style) which includes the context's aref prefix.
      # This helps keep IDs unique in HTML when headings appear within class/method documentation.
      #
      # Examples (without context):
      #   "Hello World" -> "hello-world"
      #
      # Examples (with context being class Foo):
      #   "Hello World" -> "class-foo-hello-world"
      #
      # Examples (with context being method #bar):
      #   "Hello World" -> "method-i-bar-hello-world"
      #
      #: (RDoc::Context?) -> String
      def label(context = nil)
        result = +""
        result << "#{context.aref}-" if context&.respond_to?(:aref)
        result << aref
        result
      end

      # Creates a fully-qualified legacy label for backward compatibility.
      # This is used to generate a secondary ID attribute on the heading's inner anchor,
      # allowing old-style links (e.g., #label-Hello+World) to continue working.
      #
      # Examples (without context):
      #   "hello"       -> "label-hello"
      #   "Hello World" -> "label-Hello+World"
      #
      # Examples (with context being class Foo):
      #   "hello"       -> "class-Foo-label-hello"
      #   "Hello World" -> "class-Foo-label-Hello+World"
      #
      #: (RDoc::Context?) -> String
      def legacy_label(context = nil)
        result = +""
        if context&.respond_to?(:legacy_aref)
          result << "#{context.legacy_aref}-"
        elsif context&.respond_to?(:aref)
          result << "#{context.aref}-"
        end
        result << legacy_aref
        result
      end

      # HTML markup of the text of this label without the surrounding header element.
      #: () -> String
      def plain_html
        no_image_text = text

        if matched = no_image_text.match(/rdoc-image:[^:]+:(.*)/)
          no_image_text = matched[1]
        end

        self.class.to_html.to_html(no_image_text)
      end

      # @override
      #: (PP) -> void
      def pretty_print(q)
        q.group 2, "[head: #{level} ", ']' do
          q.pp text
        end
      end
    end
  end
end
