# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module CheckConstraintAnnotation
      class Annotation
        HEADER_TEXT = "Check Constraints"

        def initialize(constraints)
          @constraints = constraints
        end

        def body
          [
            Components::BlankCommentLine.new,
            Components::Header.new(HEADER_TEXT),
            Components::BlankCommentLine.new,
            *@constraints
          ]
        end

        def to_markdown
          body.map(&:to_markdown).join("\n")
        end

        def to_rdoc
          body.map(&:to_rdoc).join("\n")
        end

        def to_yard
          body.map(&:to_yard).join("\n")
        end

        def to_default
          body.map(&:to_default).join("\n")
        end
      end
    end
  end
end
