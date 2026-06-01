# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Avoid memoizing `find_by` results with `||=`.
      #
      # It is common to see code that attempts to memoize `find_by` result by `||=`,
      # but `find_by` may return `nil`, in which case it is not memoized as intended.
      #
      # NOTE: Respecting the object shapes introduced in Ruby 3.2, instance variables used
      # for memoization that are initialized at object creation are ignored.
      #
      # @safety
      #   This cop is unsafe because detected `find_by` may not be Active Record's method,
      #   or the code may have a different purpose than memoization.
      #
      # @example
      #   # bad - exclusively doing memoization
      #   def current_user
      #     @current_user ||= User.find_by(id: session[:user_id])
      #   end
      #
      #   # good
      #   def current_user
      #     return @current_user if defined?(@current_user)
      #
      #     @current_user = User.find_by(id: session[:user_id])
      #   end
      #
      #   # bad - method contains other code
      #   def current_user
      #     @current_user ||= User.find_by(id: session[:user_id])
      #     @current_user.do_something
      #   end
      #
      #   # good
      #   def current_user
      #     if defined?(@current_user)
      #       @current_user
      #     else
      #       @current_user = User.find_by(id: session[:user_id])
      #     end
      #     @current_user.do_something
      #   end
      class FindByOrAssignmentMemoization < Base
        extend AutoCorrector

        MSG = 'Avoid memoizing `find_by` results with `||=`.'

        RESTRICT_ON_SEND = %i[find_by].freeze

        def_node_matcher :find_by_or_assignment_memoization, <<~PATTERN
          (or_asgn
            (ivasgn $_)
            $(send _ :find_by ...)
          )
        PATTERN

        # When a method body contains only memoization, the correction can be more succinct.
        def on_def(node)
          find_by_or_assignment_memoization(node.body) do |variable_name, find_by|
            next if instance_variable_assigned?(variable_name)

            add_offense(node.body) do |corrector|
              corrector.replace(
                node.body,
                <<~RUBY.rstrip
                  return #{variable_name} if defined?(#{variable_name})

                  #{variable_name} = #{find_by.source}
                RUBY
              )

              correct_to_regular_method_definition(corrector, node) if node.endless?
            end
          end
        end

        def on_send(node)
          assignment_node = node.parent

          find_by_or_assignment_memoization(assignment_node) do |variable_name, find_by|
            next if assignment_node.each_ancestor(:if).any? || instance_variable_assigned?(variable_name)

            add_offense(assignment_node) do |corrector|
              corrector.replace(
                assignment_node,
                <<~RUBY.rstrip
                  if defined?(#{variable_name})
                    #{variable_name}
                  else
                    #{variable_name} = #{find_by.source}
                  end
                RUBY
              )
            end
          end
        end

        private

        def instance_variable_assigned?(instance_variable_name)
          initialize_methods.any? do |def_node|
            def_node.each_descendant(:ivasgn).any? do |asgn_node|
              asgn_node.name == instance_variable_name
            end
          end
        end

        def initialize_methods
          @initialize_methods ||= processed_source.ast.each_descendant(:def).select { |node| node.method?(:initialize) }
        end

        def correct_to_regular_method_definition(corrector, node)
          range = node.loc.assignment.join(node.body.source_range.begin)

          corrector.replace(range, "\n")
          corrector.insert_after(node, "\nend")
        end
      end
    end
  end
end
