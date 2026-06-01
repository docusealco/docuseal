# frozen_string_literal: true

module RuboCop
  module Cop
    module Gemspec
      # Use consistent style for Gemspec attributes assignment.
      #
      # @example
      #
      #   # bad
      #   # This example uses two styles for assignment of metadata attribute.
      #   Gem::Specification.new do |spec|
      #     spec.metadata = { 'key' => 'value' }
      #     spec.metadata['another-key'] = 'another-value'
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.metadata['key'] = 'value'
      #     spec.metadata['another-key'] = 'another-value'
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.metadata = { 'key' => 'value', 'another-key' => 'another-value' }
      #   end
      #
      #   # bad
      #   # This example uses two styles for assignment of authors attribute.
      #   Gem::Specification.new do |spec|
      #     spec.authors = %w[author-0 author-1]
      #     spec.authors[2] = 'author-2'
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.authors = %w[author-0 author-1 author-2]
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.authors[0] = 'author-0'
      #     spec.authors[1] = 'author-1'
      #     spec.authors[2] = 'author-2'
      #   end
      #
      #   # good
      #   # This example uses consistent assignment per attribute,
      #   # even though two different styles are used overall.
      #   Gem::Specification.new do |spec|
      #     spec.metadata = { 'key' => 'value' }
      #     spec.authors[0] = 'author-0'
      #     spec.authors[1] = 'author-1'
      #     spec.authors[2] = 'author-2'
      #   end
      #
      class AttributeAssignment < Base
        include GemspecHelp

        MSG = 'Use consistent style for Gemspec attributes assignment.'

        def on_new_investigation
          return if processed_source.blank?

          assignments = source_assignments(processed_source.ast)
          indexed_assignments = source_indexed_assignments(processed_source.ast)

          assignments.keys.intersection(indexed_assignments.keys).each do |attribute|
            indexed_assignments[attribute].each do |node|
              add_offense(node)
            end
          end
        end

        private

        def source_assignments(ast)
          assignment_method_declarations(ast)
            .select(&:assignment_method?)
            .group_by(&:method_name)
            .transform_keys { |method_name| method_name.to_s.delete_suffix('=').to_sym }
        end

        def source_indexed_assignments(ast)
          indexed_assignment_method_declarations(ast)
            .group_by { |node| node.children.first.method_name }
        end
      end
    end
  end
end
