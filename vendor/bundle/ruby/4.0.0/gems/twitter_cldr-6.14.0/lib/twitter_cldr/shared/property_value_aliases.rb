# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared

    class PropertyValueAliases
      class << self

        def abbreviated_alias_for(property_name, property_value)
          (find_index_for(property_name, property_value) || {})
            .fetch(property_value, {})
            .fetch(:abbreviated_name, nil)
        end

        def long_alias_for(property_name, property_value)
          (find_index_for(property_name, property_value) || {})
            .fetch(property_value, {})
            .fetch(:long_name, nil)
        end

        def numeric_alias_for(property_name, property_value)
          (find_index_for(property_name, property_value) || {})
            .fetch(property_value, {})
            .fetch(:numeric, nil)
        end

        def aliases_for(property_name, property_value)
          aliases = [
            abbreviated_alias_for(property_name, property_value),
            long_alias_for(property_name, property_value),
            numeric_alias_for(property_name, property_value)
          ].compact

          aliases.delete(property_value)
          aliases
        end

        private

        def find_index_for(property_name, property_value)
          indices_for(property_name).find do |index|
            index.include?(property_value)
          end
        end

        def indices_for(property_name)
          [
            abbreviated_index_for(property_name),
            long_index_for(property_name),
            numeric_index_for(property_name)
          ].compact
        end

        def abbreviated_index_for(property_name)
          abbreviated_indices[property_name] ||=
            create_index(property_name, :abbreviated_name)
        end

        def long_index_for(property_name)
          long_indices[property_name] ||=
            create_index(property_name, :long_name)
        end

        def numeric_index_for(property_name)
          numeric_indices[property_name] ||=
            create_index(property_name, :numeric)
        end

        def create_index(property_name, field)
          (resource[property_name] || {}).each_with_object({}) do |fields, ret|
            ret[fields[field]] = fields
          end
        end

        def abbreviated_indices
          @abbreviated_indices ||= {}
        end

        def long_indices
          @long_indices ||= {}
        end

        def numeric_indices
          @numeric_indices ||= {}
        end

        def resource
          @resource ||=
            TwitterCldr.get_resource('unicode_data', 'property_value_aliases')
        end

      end
    end

  end
end
