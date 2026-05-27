# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources
    module Properties

      class BidiBracketsPropertyImporter < PropertyImporter
        DATA_FILE = 'ucd/BidiBrackets.txt'
        PROPERTY_NAME = 'Bidi_Paired_Bracket_Type'

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
            paired_bracket_type = infer_paired_bracket_type(data[2])
            ret[PROPERTY_NAME][paired_bracket_type] += code_points
          end
        end

        def infer_paired_bracket_type(str)
          TwitterCldr::Shared::Properties::BidiBrackets.bracket_types[str.upcase]
        end
      end

    end
  end
end
