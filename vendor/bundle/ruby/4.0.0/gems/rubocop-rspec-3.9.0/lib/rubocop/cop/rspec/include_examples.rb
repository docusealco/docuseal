# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for usage of `include_examples`.
      #
      # `include_examples`, unlike `it_behaves_like`, does not create its
      # own context. As such, using `subject`, `let`, `before`/`after`, etc.
      # within shared examples included with `include_examples` can have
      # unexpected behavior and side effects.
      #
      # Prefer using `it_behaves_like` instead.
      #
      # @safety
      #   `include_examples` and `it_behaves_like` have different scoping
      #   behaviors.
      #   Changing `include_examples` to `it_behaves_like` creates a new
      #   context, altering setup dependencies, which can lead to unexpected
      #   test failures.
      #   Specifically, the scope of hooks (`before`, `after`, `around`)
      #   changes, which may prevent expected setup from being inherited
      #   correctly.
      #
      #   Additionally, `let` and `subject` are affected by scoping rules.
      #   When `include_examples` is used, `let` and `subject` defined within
      #   `shared_examples` are evaluated in the caller's context, allowing
      #   access to their values.
      #   In contrast, `it_behaves_like` creates a new context, preventing
      #   access to `let` or `subject` values from the caller's context.
      #
      #   [source,ruby]
      #   ----
      #   shared_examples "mock behavior" do
      #     before do
      #       allow(service).to receive(:call).and_return("mocked response")
      #     end
      #
      #     it "returns mocked response" do
      #       expect(service.call).to eq "mocked response"
      #     end
      #   end
      #
      #   context "working example with include_examples" do
      #     let(:service) { double(:service) }
      #
      #     include_examples "mock behavior"
      #
      #     it "uses the mocked service" do
      #       expect(service.call).to eq "mocked response" # Passes
      #     end
      #   end
      #
      #   context "broken example with it_behaves_like" do
      #     let(:service) { double(:service) }
      #
      #     it_behaves_like "mock behavior"
      #
      #     it "unexpectedly does not use the mocked service" do
      #       # Fails because `it_behaves_like` does not apply the mock setup
      #       expect(service.call).to eq "mocked response"
      #     end
      #   end
      #   ----
      #
      # @example
      #   # bad
      #   include_examples 'examples'
      #
      #   # good
      #   it_behaves_like 'examples'
      #
      class IncludeExamples < Base
        extend AutoCorrector

        MSG = 'Prefer `it_behaves_like` over `include_examples`.'

        RESTRICT_ON_SEND = %i[include_examples].freeze

        def on_send(node)
          selector = node.loc.selector

          add_offense(selector) do |corrector|
            corrector.replace(selector, 'it_behaves_like')
          end
        end
      end
    end
  end
end
