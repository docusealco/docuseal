# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources
    module Properties

      class PropListImporter < PropertyImporter
        DATA_FILE = 'ucd/PropList.txt'

        requirement :unicode, Versions.unicode_version, [DATA_FILE]
        output_path 'unicode_data/properties'
        ruby_engine :mri

        private

        def source_path
          requirements[:unicode].source_path_for(DATA_FILE)
        end

        def load
          super do |data, ret|
            code_points = expand_range(data[0])
            property_name = format_property_value(data[1])
            ret[property_name][nil] += code_points
          end
        end
      end

    end
  end
end
