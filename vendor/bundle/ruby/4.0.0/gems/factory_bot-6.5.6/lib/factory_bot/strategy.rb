require "factory_bot/strategy/build"
require "factory_bot/strategy/create"
require "factory_bot/strategy/attributes_for"
require "factory_bot/strategy/stub"
require "factory_bot/strategy/null"

module FactoryBot
  module Strategy
    def self.lookup_strategy(name_or_object)
      return name_or_object if name_or_object.is_a?(Class)

      FactoryBot::Internal.strategy_by_name(name_or_object)
    end
  end
end
