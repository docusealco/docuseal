# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for `BEGIN` blocks. They are Perl-style constructs that execute
      # code before the rest of the file is parsed, making the control flow
      # harder to follow and reason about.
      #
      # @example
      #   # bad
      #   BEGIN { test }
      #
      class BeginBlock < Base
        MSG = 'Avoid the use of `BEGIN` blocks.'

        def on_preexe(node)
          add_offense(node.loc.keyword)
        end
      end
    end
  end
end
