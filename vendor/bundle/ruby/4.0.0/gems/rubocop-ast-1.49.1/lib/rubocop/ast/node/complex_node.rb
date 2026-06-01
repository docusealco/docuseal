# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `complex` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available to
    # all `complex` nodes within RuboCop.
    class ComplexNode < Node
      include BasicLiteralNode
      include NumericNode
    end
  end
end
