# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources

    class UnicodePropertyAliasesImporter < Importer
      PROPERTY_ALIASES_FILE = 'ucd/PropertyAliases.txt'
      PROPERTY_VALUE_ALIASES_FILE = 'ucd/PropertyValueAliases.txt'

      requirement :unicode, Versions.unicode_version, [PROPERTY_ALIASES_FILE, PROPERTY_VALUE_ALIASES_FILE]
      output_path 'unicode_data'
      ruby_engine :mri

      private

      def execute
        FileUtils.mkdir_p(output_path)

        File.write(
          File.join(output_path, 'property_value_aliases.yml'),
          YAML.dump(parse_property_value_aliases)
        )

        File.write(
          File.join(output_path, 'property_aliases.yml'),
          YAML.dump(parse_property_aliases)
        )
      end

      def output_path
        params.fetch(:output_path)
      end

      def parse_file(file, &block)
        UnicodeFileParser.parse_standard_file(file, &block)
      end

      def parse_property_aliases
        Hash.new { |h, k| h[k] = [] }.tap do |result|
          parse_file(property_aliases_data_file) do |data|
            property = data[0]
            result[property] = parse_alias(data)
          end
        end
      end

      def parse_property_value_aliases
        Hash.new { |h, k| h[k] = [] }.tap do |result|
          parse_file(property_value_aliases_data_file) do |data|
            property_value = data[0]
            result[property_value] << if property_value == 'ccc'
              parse_ccc_value_alias(data)
            else
              parse_value_alias(data)
            end
          end
        end
      end

      def parse_alias(data)
        {
          long_name: data[1],
          additional: data[2..-1]
        }
      end

      def parse_value_alias(data)
        {
          abbreviated_name: data[1],
          long_name: data[2]
        }
      end

      def parse_ccc_value_alias(data)
        {
          numeric: data[1],  # don't know what this means
          abbreviated_name: data[2],
          long_name: data[3]
        }
      end

      def property_aliases_data_file
        requirements[:unicode].source_path_for(PROPERTY_ALIASES_FILE)
      end

      def property_value_aliases_data_file
        requirements[:unicode].source_path_for(PROPERTY_VALUE_ALIASES_FILE)
      end
    end

  end
end
