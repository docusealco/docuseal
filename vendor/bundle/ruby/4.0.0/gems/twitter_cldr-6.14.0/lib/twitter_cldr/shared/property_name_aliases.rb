# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared

    class PropertyNameAliases
      class << self

        def abbreviated_alias_for(long_name)
          index.fetch(long_name, nil)
        end

        def long_alias_for(abbreviated_name)
          resource.fetch(abbreviated_name, {}).fetch(:long_name, nil)
        end

        def aliases_for(property_name)
          fields = (resource[property_name] || {})
          Array(fields[:long_name]) +
            Array(fields[:additional]) +
            Array(index[property_name])
        end

        private

        def index
          @index ||= resource.each_with_object({}) do |(abbr_name, fields), ret|
            ret[fields[:long_name]] = abbr_name

            fields[:additional].each do |additional_alias|
              ret[additional_alias] = abbr_name
            end
          end
        end

        def resource
          @resource ||=
            TwitterCldr.get_resource('unicode_data', 'property_aliases')
        end

      end
    end

  end
end
