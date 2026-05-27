# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources
    module Properties

      class ScriptExtensionsPropertyImporter < PropertyImporter
        DATA_FILE = 'ucd/ScriptExtensions.txt'
        PROPERTY_NAME = 'Script_Extensions'

        requirement :unicode, Versions.unicode_version, [DATA_FILE]
        output_path 'unicode_data/properties'
        ruby_engine :mri

        def property_name
          PROPERTY_NAME
        end

        private

        def source_path
          requirements[:unicode].source_path_for(DATA_FILE)
        end

        def load
          super do |data, ret|
            code_points = expand_range(data[0])
            property_values = data[1].split(' ')

            property_values.each do |property_value|
              ret[property_name][property_value] += code_points
            end
          end
        end
      end

    end
  end
end
