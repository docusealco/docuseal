require "generators/factory_bot"
require "generators/factory_bot/model/model_generator"
require "factory_bot_rails"

module FactoryBot
  module Generators
    FixedAttribute = Struct.new(:name, :default)

    class AuthenticationGenerator < ModelGenerator
      source_paths << File.join(File.dirname(__FILE__), "../model/templates")

      private

      def attributes
        [
          FixedAttribute.new(:email_address, "user@example.com"),
          FixedAttribute.new(:password, "password")
        ]
      end
    end
  end
end
