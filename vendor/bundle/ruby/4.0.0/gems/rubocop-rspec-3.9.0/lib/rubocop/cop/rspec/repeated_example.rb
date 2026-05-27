# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check for repeated examples within example groups.
      #
      # @example
      #
      #   it 'is valid' do
      #     expect(user).to be_valid
      #   end
      #
      #   it 'validates the user' do
      #     expect(user).to be_valid
      #   end
      #
      class RepeatedExample < Base
        MSG = "Don't repeat examples within an example group. " \
              'Repeated on line(s) %<lines>s.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example_group?(node)

          find_repeated_examples(node).each do |repeated_examples|
            add_offenses_for_repeated_group(repeated_examples)
          end
        end

        private

        def find_repeated_examples(node)
          examples = RuboCop::RSpec::ExampleGroup.new(node).examples

          examples
            .group_by { |example| build_example_signature(example) }
            .values
            .select { |group| group.size > 1 }
        end

        def build_example_signature(example)
          signature = [example.metadata, example.implementation]
          if example.definition.method?(:its)
            signature << example.definition.arguments
          end
          signature
        end

        def add_offenses_for_repeated_group(repeated_examples)
          repeated_examples.each do |example|
            other_lines = extract_other_lines(repeated_examples, example)
            add_offense(example.to_node, message: message(other_lines))
          end
        end

        def extract_other_lines(examples_group, current_example)
          current_node = current_example.to_node

          examples_group
            .reject { |ex| ex.to_node.equal?(current_node) }
            .map { |ex| ex.to_node.first_line }
            .uniq
            .sort
        end

        def message(other_lines)
          format(MSG, lines: other_lines.join(', '))
        end
      end
    end
  end
end
