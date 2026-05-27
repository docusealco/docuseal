module RSpec
  module Rails
    # @private
    module FixtureSupport
      if defined?(ActiveRecord::TestFixtures)
        extend ActiveSupport::Concern
        include RSpec::Rails::SetupAndTeardownAdapter
        include RSpec::Rails::MinitestLifecycleAdapter
        include RSpec::Rails::MinitestAssertionAdapter
        include ActiveRecord::TestFixtures

        # @private prevent ActiveSupport::TestFixtures to start a DB transaction.
        # Monkey patched to avoid collisions with 'let(:name)' since Rails 6.1
        def run_in_transaction?
          current_example_name = (RSpec.current_example && RSpec.current_example.metadata[:description])
          use_transactional_tests && !self.class.uses_transaction?(current_example_name)
        end

        included do
          if RSpec.configuration.use_active_record?
            include Fixtures

            self.fixture_paths = RSpec.configuration.fixture_paths

            self.use_transactional_tests = RSpec.configuration.use_transactional_fixtures
            self.use_instantiated_fixtures = RSpec.configuration.use_instantiated_fixtures

            fixtures RSpec.configuration.global_fixtures if RSpec.configuration.global_fixtures
          end
        end

        module Fixtures
          extend ActiveSupport::Concern

          class_methods do
            def fixtures(*args)
              super.tap do
                fixture_sets.each_pair do |method_name, fixture_name|
                  proxy_method_warning_if_called_in_before_context_scope(method_name, fixture_name)
                end
              end
            end

            def proxy_method_warning_if_called_in_before_context_scope(method_name, fixture_name)
              define_method(method_name) do |*args, **kwargs, &blk|
                if RSpec.current_scope == :before_context_hook
                  RSpec.warn_with("Calling fixture method in before :context ")
                else
                  access_fixture(fixture_name, *args, **kwargs, &blk)
                end
              end
            end
          end
        end
      end
    end
  end
end
