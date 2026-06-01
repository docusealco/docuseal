# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that `all` matcher is used instead of iterating over an array.
      #
      # @example
      #   # bad
      #   it 'validates users' do
      #     [user1, user2, user3].each { |user| expect(user).to be_valid }
      #   end
      #
      #   # good
      #   it 'validates users' do
      #     expect([user1, user2, user3]).to all(be_valid)
      #   end
      #
      class IteratedExpectation < Base
        extend AutoCorrector

        MSG = 'Prefer using the `all` matcher instead ' \
              'of iterating over an array.'

        # @!method each?(node)
        def_node_matcher :each?, <<~PATTERN
          (block
            (send ... :each)
            (args (arg $_))
            (...)
          )
        PATTERN

        # @!method each_numblock?(node)
        def_node_matcher :each_numblock?, <<~PATTERN
          (numblock
            (send ... :each) _ (...)
          )
        PATTERN

        # @!method expectation?(node)
        def_node_matcher :expectation?, <<~PATTERN
          (send (send nil? :expect (lvar %)) :to ...)
        PATTERN

        def on_block(node)
          each?(node) do |arg|
            check_offense(node, arg)
          end
        end

        def on_numblock(node)
          each_numblock?(node) do
            check_offense(node, :_1)
          end
        end

        private

        def check_offense(node, argument)
          if single_expectation?(node.body, argument)
            add_offense(node.send_node) do |corrector|
              next unless node.body.arguments.one?
              next if uses_argument_in_matcher?(node, argument)

              corrector.replace(node, single_expectation_replacement(node))
            end
          elsif only_expectations?(node.body, argument)
            add_offense(node.send_node)
          end
        end

        def single_expectation_replacement(node)
          collection = node.receiver.source
          matcher = node.body.first_argument.source

          "expect(#{collection}).to all(#{matcher})"
        end

        def uses_argument_in_matcher?(node, argument)
          node.body.first_argument.each_descendant.any?(s(:lvar, argument))
        end

        def single_expectation?(body, arg)
          expectation?(body, arg)
        end

        def only_expectations?(body, arg)
          return false unless body.each_child_node.any?

          body.each_child_node.all? { |child| expectation?(child, arg) }
        end
      end
    end
  end
end
