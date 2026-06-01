# frozen_string_literal: true

module Faker
  class Games
    class HeroesOfTheStorm < Base
      class << self
        ##
        # Produces a battleground from Heroes of the Storm.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::HeroesOfTheStorm.battleground #=> "Towers of Doom"
        #
        # @faker.version 1.9.2
        def battleground
          fetch('heroes_of_the_storm.battlegrounds')
        end

        ##
        # Produces a class name from Heroes of the Storm.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::HeroesOfTheStorm.class_name #=> "Support"
        #
        # @faker.version 2.13.0
        def class_name
          fetch('heroes_of_the_storm.class_names')
        end

        ##
        # Produces a hero from Heroes of the Storm.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::HeroesOfTheStorm.hero #=> "Illidan"
        #
        # @faker.version 1.9.2
        def hero
          fetch('heroes_of_the_storm.heroes')
        end

        ##
        # Produces a quote from Heroes of the Storm.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::HeroesOfTheStorm.quote #=> "MEAT!!!"
        #
        # @faker.version 1.9.2
        def quote
          fetch('heroes_of_the_storm.quotes')
        end
      end
    end
  end
end
