# frozen_string_literal: true

module Faker
  class TvShows
    class SouthPark < Base
      flexible :south_park

      class << self
        ##
        # Produces a character from South Park.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SouthPark.character #=> "Mr. Garrison"
        #
        # @faker.version 1.9.2
        def character
          fetch('south_park.characters')
        end

        ##
        # Produces a quote from South Park.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SouthPark.quote
        #     #=> "I'm just getting a little cancer Stan."
        #
        # @faker.version 1.9.2
        def quote
          fetch('south_park.quotes')
        end

        ##
        # Produces an episode name from South Park.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SouthPark.episode_name
        #     #=> "Make Love, Not Warcraft"
        #
        # @faker.version next

        def episode_name
          fetch('south_park.episodes')
        end
      end
    end
  end
end
