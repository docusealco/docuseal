# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for local variables from outer scopes used inside examples.
      #
      # Local variables assigned outside an example but used within it act
      # as shared state, which can make tests non-deterministic.
      #
      # @example
      #   # bad - outside variable used in a hook
      #   user = create(:user)
      #
      #   before { user.update(admin: true) }
      #
      #   # good
      #   let(:user) { create(:user) }
      #
      #   before { user.update(admin: true) }
      #
      #   # bad - outside variable used in an example
      #   user = create(:user)
      #
      #   it 'is persisted' do
      #     expect(user).to be_persisted
      #   end
      #
      #   # good
      #   let(:user) { create(:user) }
      #
      #   it 'is persisted' do
      #     expect(user).to be_persisted
      #   end
      #
      #   # also good - assigning the variable within the example
      #   it 'is persisted' do
      #     user = create(:user)
      #
      #     expect(user).to be_persisted
      #   end
      #
      #   # bad - outside variable passed to included examples
      #   attrs = ['foo', 'bar']
      #
      #   it_behaves_like 'some examples', attrs
      #
      #   # good
      #   it_behaves_like 'some examples' do
      #     let(:attrs) { ['foo', 'bar'] }
      #   end
      #
      #   # good - when variable is used only as example description
      #   attribute = 'foo'
      #
      #   it "#{attribute} is persisted" do
      #     expectations
      #   end
      #
      #   # good - when variable is used only in example metadata
      #   skip_message = 'not yet implemented'
      #
      #   it 'does something', skip: skip_message do
      #     expectations
      #   end
      #
      #   # good - when variable is used only to include other examples
      #   examples = foo ? 'some examples' : 'other examples'
      #
      #   it_behaves_like examples, another_argument
      #
      class LeakyLocalVariable < Base
        MSG = 'Do not use local variables defined outside of ' \
              'examples inside of them.'

        # @!method example_method?(node)
        def_node_matcher :example_method?, <<~PATTERN
          (send nil? #Examples.all _)
        PATTERN

        # @!method includes_method?(node)
        def_node_matcher :includes_method?, <<~PATTERN
          (send nil? #Includes.all ...)
        PATTERN

        def self.joining_forces
          VariableForce
        end

        def after_leaving_scope(scope, _variable_table)
          scope.variables.each_value { |variable| check_references(variable) }
        end

        private

        def check_references(variable)
          variable.assignments.each do |assignment|
            next if part_of_example_scope?(assignment.node)

            assignment.references.each do |reference|
              next unless inside_describe_block?(reference)
              next unless part_of_example_scope?(reference)
              next if allowed_reference?(reference)

              add_offense(assignment.node)
            end
          end
        end

        def allowed_reference?(node)
          node.each_ancestor.any? do |ancestor|
            next true if example_method?(ancestor)
            next true if in_example_arguments?(ancestor, node)

            if includes_method?(ancestor)
              next allowed_includes_arguments?(ancestor, node)
            end

            false
          end
        end

        def in_example_arguments?(ancestor, node)
          return false unless ancestor.send_type?
          return false unless Examples.all(ancestor.method_name)

          ancestor.arguments.any? do |arg|
            arg.equal?(node) || arg.each_descendant.any?(node)
          end
        end

        def allowed_includes_arguments?(node, argument)
          node.arguments[1..].all? do |argument_node|
            next true if argument_node.type?(:dstr, :dsym)

            argument_node != argument &&
              argument_node.each_descendant.none?(argument)
          end
        end

        def part_of_example_scope?(node)
          node.each_ancestor.any? { |ancestor| example_scope?(ancestor) }
        end

        def example_scope?(node)
          subject?(node) || let?(node) || hook?(node) || example?(node) ||
            include?(node)
        end

        def inside_describe_block?(node)
          node.each_ancestor(:block).any? { |ancestor| spec_group?(ancestor) }
        end
      end
    end
  end
end
