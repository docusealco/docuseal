# frozen_string_literal: true

module Faker
  class JapaneseMedia
    class FullmetalAlchemistBrotherhood < Base
      class << self
        ##
        # Produces a character from FullmetalAlchemistBrotherhood.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::FullmetalAlchemistBrotherhood.character #=> "Edward Elric"
        #
        # @faker.version next
        def character
          fetch('fullmetal_alchemist_brotherhood.characters')
        end

        ##
        # Produces a cities from FullmetalAlchemistBrotherhood.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::FullmetalAlchemistBrotherhood.city #=> "Central City"
        #
        # @faker.version next
        def city
          fetch('fullmetal_alchemist_brotherhood.cities')
        end

        ##
        # Produces a country from FullmetalAlchemistBrotherhood.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::FullmetalAlchemistBrotherhood.country #=> "Xing"
        #
        # @faker.version next
        def country
          fetch('fullmetal_alchemist_brotherhood.countries')
        end
      end
    end
  end
end
