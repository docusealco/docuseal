# frozen_string_literal: true

module RuboCop
  module Cop
    module Gemspec
      # An attribute assignment method calls should be listed only once
      # in a gemspec.
      #
      # Assigning to an attribute with the same name using `spec.foo =` or
      # `spec.attribute#[]=` will be an unintended usage. On the other hand,
      # duplication of methods such # as `spec.requirements`,
      # `spec.add_runtime_dependency`, and others are permitted because it is
      # the intended use of appending values.
      #
      # @example
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.name = 'rubocop'
      #     spec.name = 'rubocop2'
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.name = 'rubocop'
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.requirements << 'libmagick, v6.0'
      #     spec.requirements << 'A good graphics card'
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.add_dependency('parallel', '~> 1.10')
      #     spec.add_dependency('parser', '>= 2.3.3.1', '< 3.0')
      #   end
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.metadata["key"] = "value"
      #     spec.metadata["key"] = "value"
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.metadata["key"] = "value"
      #   end
      #
      class DuplicatedAssignment < Base
        include RangeHelp
        include GemspecHelp

        MSG = '`%<assignment>s` method calls already given on line ' \
              '%<line_of_first_occurrence>d of the gemspec.'

        def on_new_investigation
          return if processed_source.blank?

          process_assignment_method_nodes
          process_indexed_assignment_method_nodes
        end

        private

        def process_assignment_method_nodes
          duplicated_assignment_method_nodes.each do |nodes|
            nodes[1..].each do |node|
              register_offense(node, node.method_name, nodes.first.first_line)
            end
          end
        end

        def process_indexed_assignment_method_nodes
          duplicated_indexed_assignment_method_nodes.each do |nodes|
            nodes[1..].each do |node|
              assignment = "#{node.children.first.method_name}[#{node.first_argument.source}]="
              register_offense(node, assignment, nodes.first.first_line)
            end
          end
        end

        def duplicated_assignment_method_nodes
          assignment_method_declarations(processed_source.ast)
            .select(&:assignment_method?)
            .group_by(&:method_name)
            .values
            .select { |nodes| nodes.size > 1 }
        end

        def duplicated_indexed_assignment_method_nodes
          indexed_assignment_method_declarations(processed_source.ast)
            .group_by { |node| [node.children.first.method_name, node.first_argument] }
            .values
            .select { |nodes| nodes.size > 1 }
        end

        def register_offense(node, assignment, line_of_first_occurrence)
          line_range = node.loc.column...node.loc.last_column
          offense_location = source_range(processed_source.buffer, node.first_line, line_range)
          message = format(
            MSG,
            assignment: assignment,
            line_of_first_occurrence: line_of_first_occurrence
          )
          add_offense(offense_location, message: message)
        end
      end
    end
  end
end
