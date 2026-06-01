# frozen_string_literal: true

module Faker
  class Travel
    class TrainStation < Base
      class << self
        ##
        # Produces random Train Station by name and takes optional arguments for region and type
        #
        # @param region [String] Train station region: germany, spain, united_kingdom, united_states
        #
        # @param type [String] Train station type: metro, railway
        #
        # @return [String]
        #
        # @examples
        # Faker::Travel::TrainStation.name(region: 'united_kingdom', type: 'metro') => "Brockley"
        # Faker::Travel::TrainStation.name(type: 'railway') => "Düsseldorf Hauptbahnhof"
        # Faker::Travel::TrainStation.name(region: 'spain') => "Santa Eulàlia"
        #
        # @faker.version next
        def name(region: nil, type: nil)
          region, type = fill_missing_inputs_with_samples(region, type)
          fetch("train_station.#{region}.#{type}")
        end

        private

        def fill_missing_inputs_with_samples(region, type)
          regions = %w[germany spain united_kingdom united_states]
          types = %w[metro railway]

          if region.nil? && type.nil?
            region = sample(regions)
            type = sample(types)
          elsif region.nil?
            validate_arguments(type, types, 'type')
            region = sample(regions)
          elsif type.nil?
            validate_arguments(region, regions, 'region')
            type = sample(types)
          end
          [region, type]
        end

        def validate_arguments(argument, correct_values, argument_name)
          return if correct_values.include?(argument)

          raise ArgumentError, "'#{argument}' not found, #{argument_name} can be blank, or one of the following, as strings: #{correct_values.join(', ')}"
        end
      end
    end
  end
end
