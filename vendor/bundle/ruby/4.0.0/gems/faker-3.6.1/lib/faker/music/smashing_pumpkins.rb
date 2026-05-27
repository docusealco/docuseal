# frozen_string_literal: true

require_relative 'music'

module Faker
  class Music
    class SmashingPumpkins < Base
      class << self
        ##
        # Produces the name of a member of the Smashing Pumpkins (current and former)
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::SmashingPumpkins.musician #=> "Billy Corgan"
        #
        # @faker.version next
        def musician
          fetch('smashing_pumpkins.musicians')
        end

        ##
        # Produces the name of an album by the Smashing Pumpkins.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::SmashingPumpkins.album #=> "Siamese Dream"
        #
        # @faker.version next
        def album
          fetch('smashing_pumpkins.albums')
        end

        ##
        # Produces a random Smashing Pumpkins song lyric.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::SmashingPumpkins.lyric #=> "Despite all my rage, I am still just a rat in a cage"
        #   Faker::Music::SmashingPumpkins.lyric #=> "Breathin' underwater, and livin' under glass"
        #
        # @faker.version next
        def lyric
          fetch('smashing_pumpkins.lyric')
        end

        ##
        # Produces the name of a song by the Smashing Pumpkins.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::SmashingPumpkins.song #=> "Stand Inside My Love"
        #
        # @faker.version next
        def song
          fetch('smashing_pumpkins.songs')
        end
      end
    end
  end
end
