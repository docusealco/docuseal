# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for local variables and method parameters named `it`,
      # where `it` can refer to the first anonymous parameter as of Ruby 3.4.
      # Use a meaningful variable name instead.
      #
      # NOTE: Although Ruby allows reassigning `it` in these cases, it could
      # cause confusion if `it` is used as a block parameter elsewhere.
      #
      # @example
      #   # bad
      #   it = 5
      #
      #   # good
      #   var = 5
      #
      #   # bad
      #   def foo(it)
      #   end
      #
      #   # good
      #   def foo(arg)
      #   end
      #
      #   # bad
      #   def foo(it = 5)
      #   end
      #
      #   # good
      #   def foo(arg = 5)
      #   end
      #
      #   # bad
      #   def foo(*it)
      #   end
      #
      #   # good
      #   def foo(*args)
      #   end
      #
      #   # bad
      #   def foo(it:)
      #   end
      #
      #   # good
      #   def foo(arg:)
      #   end
      #
      #   # bad
      #   def foo(it: 5)
      #   end
      #
      #   # good
      #   def foo(arg: 5)
      #   end
      #
      #   # bad
      #   def foo(**it)
      #   end
      #
      #   # good
      #   def foo(**kwargs)
      #   end
      #
      #   # bad
      #   def foo(&it)
      #   end
      #
      #   # good
      #   def foo(&block)
      #   end
      class ItAssignment < Base
        MSG = '`it` is the default block parameter; consider another name.'

        def on_lvasgn(node)
          return unless node.name == :it

          add_offense(node.loc.name)
        end
        alias on_arg on_lvasgn
        alias on_optarg on_lvasgn
        alias on_restarg on_lvasgn
        alias on_blockarg on_lvasgn
        alias on_kwarg on_lvasgn
        alias on_kwoptarg on_lvasgn
        alias on_kwrestarg on_lvasgn
      end
    end
  end
end
