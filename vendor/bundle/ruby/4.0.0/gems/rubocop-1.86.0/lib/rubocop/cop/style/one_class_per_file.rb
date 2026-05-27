# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks that each source file defines at most one top-level class or module.
      #
      # Keeping one class or module per file makes it easier to find and navigate
      # code, and follows the convention used by most Ruby projects.
      #
      # Classes and modules listed in `AllowedClasses` are not counted toward the
      # limit. This is useful for small ancillary classes like custom exception
      # classes that logically belong with the main class.
      #
      # @example
      #   # bad
      #   class Foo
      #   end
      #
      #   class Bar
      #   end
      #
      #   # bad
      #   class Foo
      #   end
      #
      #   module Bar
      #   end
      #
      #   # good
      #   class Foo
      #   end
      #
      #   # good
      #   class Foo
      #     class Bar
      #     end
      #   end
      #
      # @example AllowedClasses: ['AllowedClass']
      #   # good
      #   class Foo
      #   end
      #
      #   class AllowedClass
      #   end
      #
      class OneClassPerFile < Base
        include RangeHelp

        MSG = 'Do not define multiple classes/modules at the top level in a single file.'

        def on_new_investigation
          @top_level_definitions = []
        end

        def on_class(node)
          check_top_level(node)
        end

        def on_module(node)
          check_top_level(node)
        end

        private

        def check_top_level(node)
          return unless top_level_definition?(node)
          return if allowed_class?(node)

          @top_level_definitions << node
          return unless @top_level_definitions.length > 1

          add_offense(range_between(node.source_range.begin_pos, node.loc.name.end_pos))
        end

        def top_level_definition?(node)
          if node.parent&.begin_type?
            node.parent.root?
          else
            node.root?
          end
        end

        def allowed_class?(node)
          allowed_classes.include?(node.identifier.short_name)
        end

        def allowed_classes
          @allowed_classes ||= cop_config.fetch('AllowedClasses', []).map(&:intern)
        end
      end
    end
  end
end
