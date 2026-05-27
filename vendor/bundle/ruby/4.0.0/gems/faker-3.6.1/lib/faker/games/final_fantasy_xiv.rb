# frozen_string_literal: true

module Faker
  class Games
    class FinalFantasyXIV < Base
      class << self
        ##
        # Produces the name of a character from FFXIV.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::FinalFantasyXIV.character #=> "Y'shtola Rhul"
        #
        # @faker.version next
        def character
          fetch('games.final_fantasy_xiv.characters')
        end

        ##
        # Produces a job name from Final Fantasy XIV. Either a battle or non-battle playable job.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::FinalFantasyXIV.job #=> "Paladin"
        #
        # @faker.version next
        def job
          fetch('games.final_fantasy_xiv.jobs')
        end

        # Produces the name of a playable race from Final Fantasy XIV.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::FinalFantasyXIV.race #=> "Miqo'te"
        #
        # @faker.version next
        def race
          fetch('games.final_fantasy_xiv.races')
        end

        ##
        # Produces a data center from Final Fantasy XIV.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::FinalFantasyXIV.data_center #=> "Aether"
        #
        # @faker.version next
        def data_center
          fetch('games.final_fantasy_xiv.data_centers')
        end

        ##
        # Produces a geographical zone from Final Fantasy XIV.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::FinalFantasyXIV.zone #=> "Eastern La Noscea"
        #
        # @faker.version next
        def zone
          fetch('games.final_fantasy_xiv.zones')
        end
      end
    end
  end
end
