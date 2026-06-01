# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for unreachable `in` pattern branches in `case...in` statements.
      #
      # An `in` branch is unreachable when a previous branch uses an unguarded
      # catch-all pattern that matches any value unconditionally. Any `in` branches
      # (and `else`) that follow such a catch-all are dead code.
      #
      # A catch-all pattern is one of:
      #
      # * A bare variable capture (`in x`)
      # * An underscore (`in _`)
      # * A pattern alias where the left side is a catch-all (`in _ => y`)
      # * An alternation pattern where at least one alternative is a catch-all
      #   (`in _ | Integer`)
      #
      # NOTE: A catch-all pattern with a guard clause (e.g., `in _ if condition`)
      # does NOT make subsequent branches unreachable because the guard might
      # not be satisfied.
      #
      # @example
      #
      #   # bad
      #   case value
      #   in Integer
      #     handle_integer
      #   in x
      #     handle_other
      #   in String
      #     handle_string
      #   else
      #     handle_else
      #   end
      #
      #   # good
      #   case value
      #   in Integer
      #     handle_integer
      #   in String
      #     handle_string
      #   in x
      #     handle_other
      #   end
      #
      #   # bad - else is unreachable after catch-all
      #   case value
      #   in Integer
      #     handle_integer
      #   in _
      #     handle_other
      #   else
      #     handle_else
      #   end
      #
      #   # good - guard clause means catch-all might not match
      #   case value
      #   in x if x.positive?
      #     handle_positive
      #   in Integer
      #     handle_integer
      #   else
      #     handle_other
      #   end
      #
      class UnreachablePatternBranch < Base
        extend TargetRubyVersion

        MSG = 'Unreachable `in` pattern branch detected.'
        MSG_ELSE = 'Unreachable `else` branch detected.'

        minimum_target_ruby_version 2.7

        def on_case_match(case_node)
          catch_all_found = false

          case_node.in_pattern_branches.each do |in_pattern_node|
            if catch_all_found
              add_offense(in_pattern_node)
              next
            end

            pattern = in_pattern_node.pattern
            guard = in_pattern_node.children[1]

            catch_all_found = true if catch_all_pattern?(pattern) && guard.nil?
          end

          return unless catch_all_found && case_node.else?

          add_offense(case_node.loc.else, message: MSG_ELSE)
        end

        private

        def catch_all_pattern?(pattern)
          case pattern.type
          when :match_var
            true
          when :match_as, :begin
            catch_all_pattern?(pattern.children[0])
          when :match_alt
            pattern.children.any? { |child| catch_all_pattern?(child) }
          else
            false
          end
        end
      end
    end
  end
end
