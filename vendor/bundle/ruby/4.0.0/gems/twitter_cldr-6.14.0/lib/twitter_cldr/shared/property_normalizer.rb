# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared

    class PropertyNormalizer
      attr_reader :database

      def initialize(database)
        @database = database
      end

      def normalize(property_name, property_value = nil)
        candidates = find_property_name_candidates(property_name)

        if property_value
          name, value = resolve_candidates(candidates, property_value)
        else
          candidates.each do |c|
            if name = resolve_property_name_case(c)
              break
            end
          end

          value = nil
        end

        [name, value]
      end

      private

      def resolve_candidates(property_name_candidates, property_value)
        value_candidates = find_property_value_candidates(
          property_name_candidates, property_value
        )

        resolve_name_value_candidates(
          property_name_candidates, value_candidates
        )
      end

      def resolve_name_value_candidates(property_name_candidates, value_candidates)
        property_name_candidates.each do |name_candidate|
          value_candidates.each do |value_candidate|
            if cased_property_name = resolve_property_name_case(name_candidate)
              if value_candidate
                cased_property_value = resolve_property_value_case(
                  cased_property_name, value_candidate
                )

                if cased_property_value
                  return [
                    cased_property_name, cased_property_value
                  ]
                end
              else
                if database.include?(cased_property_name, value_candidate)
                  return [
                    cased_property_name, value_candidate
                  ]
                end
              end
            end
          end
        end

        []
      end

      def resolve_property_name_case(property_name)
        name_idx = database.property_names.index do |name|
          name.casecmp(property_name).zero?
        end

        database.property_names[name_idx] if name_idx
      end

      def resolve_property_value_case(property_name, property_value)
        property_values = database.property_values_for(property_name)

        if property_values
          value_idx = property_values.index do |value|
            value.casecmp(property_value).zero?
          end

          property_values[value_idx] if value_idx
        end
      end

      def find_property_name_candidates(property_name)
        aliases = PropertyNameAliases.aliases_for(property_name)
        aliases << property_name
        aliases.uniq
      end

      def find_property_value_candidates(property_name_candidates, property_value)
        property_name_candidates.flat_map do |property_name|
          PropertyValueAliases.aliases_for(property_name, property_value) + [property_value]
        end.uniq
      end
    end

  end
end
