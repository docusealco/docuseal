# frozen_string_literal: true

module Faker
  class Locations
    class Australia < Base
      class << self
        ##
        # Produces a location in Australia
        #
        # @return [String]
        #
        # @example
        #   Faker::Locations::Australia.location
        #    #=> "Sydney"
        #
        # @faker.version next
        def location
          fetch('locations.australia.locations')
        end

        # Produces an Australian animal
        #
        # @return [String]
        #
        # @example
        #   Faker::Locations::Australia.animal
        #    #=> "Dingo"
        #
        # @faker.version next
        def animal
          fetch('locations.australia.animals')
        end

        # Produces an Australian State or Territory
        #
        # @return [String]
        #
        # @example
        #   Faker::Locations::Australia.state
        #    #=> "New South Wales"
        #
        # @faker.version next
        def state
          fetch('locations.australia.states')
        end
      end
    end
  end
end
