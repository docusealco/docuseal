# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources
    module Properties

      class PropertyImporter < Importer
        private

        def execute
          load.each_pair do |property_name, property_values|
            property_values.each_pair do |property_value, ranges|
              database.store(property_name, property_value, ranges)
            end
          end
        end

        def database
          @database ||= TwitterCldr::Shared::PropertiesDatabase.new(
            params.fetch(:output_path)
          )
        end

        def parse_file(file, &block)
          UnicodeFileParser.parse_standard_file(file, &block)
        end

        def load
          results = Hash.new do |h, k|
            h[k] = Hash.new { |h, k| h[k] = [] }
          end

          rangify_hash(
            parse_file(source_path).each_with_object(results) do |data, ret|
              next unless data[0].size > 0

              if block_given?
                yield data, ret
              else
                code_points = expand_range(data[0])
                property_value = format_property_value(data[1])
                ret[property_name][property_value] += code_points
              end
            end
          )
        end

        def rangify_hash(hash)
          hash.each_with_object({}) do |(key, value), ret|
            ret[key] = case value
              when Hash
                rangify_hash(value)
              when Array
                TwitterCldr::Utils::RangeSet.from_array(value)
            end
          end
        end

        def expand_range(str)
          initial, final = str.split("..")
          (initial.to_i(16)..(final || initial).to_i(16)).to_a
        end

        def format_property_value(value)
          value
        end
      end

    end
  end
end
