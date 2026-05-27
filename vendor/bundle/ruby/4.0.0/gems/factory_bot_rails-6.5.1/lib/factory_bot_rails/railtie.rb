# frozen_string_literal: true

require "factory_bot"
require "factory_bot_rails/generator"
require "factory_bot_rails/reloader"
require "factory_bot_rails/factory_validator"
require "factory_bot_rails/file_fixture_support"
require "rails"

module FactoryBotRails
  class Railtie < Rails::Railtie
    config.factory_bot = ActiveSupport::OrderedOptions.new
    config.factory_bot.definition_file_paths = FactoryBot.definition_file_paths
    config.factory_bot.validator = FactoryBotRails::FactoryValidator.new
    config.factory_bot.file_fixture_support = true

    initializer "factory_bot.set_fixture_replacement" do
      Generator.new(config).run
    end

    initializer "factory_bot.set_factory_paths" do
      FactoryBot.definition_file_paths = definition_file_paths
    end

    config.after_initialize do
      if config.factory_bot.file_fixture_support
        FactoryBot::SyntaxRunner.include FactoryBotRails::FileFixtureSupport

        ActiveSupport.on_load :active_support_test_case do
          setup { FactoryBot::SyntaxRunner.file_fixture_support = self }
        end

        if defined?(RSpec) && RSpec.respond_to?(:configure)
          RSpec.configure do |config|
            config.before { FactoryBot::SyntaxRunner.file_fixture_support = self }
          end
        end
      end
    end

    config.after_initialize do |app|
      FactoryBot.find_definitions
      Reloader.new(app).run
      app.config.factory_bot.validator.run
    end

    private

    def definition_file_paths
      config.factory_bot.definition_file_paths.map do |path|
        Rails.root.join(path)
      end
    end
  end
end
