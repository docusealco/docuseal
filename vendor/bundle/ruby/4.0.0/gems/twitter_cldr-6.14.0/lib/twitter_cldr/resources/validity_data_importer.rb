# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'fileutils'
require 'nokogiri'

module TwitterCldr
  module Resources

    class ValidityDataImporter < Importer
      requirement :cldr, Versions.cldr_version
      output_path 'shared/'
      ruby_engine :mri

      def execute
        output_file = File.join(output_path, 'validity_data.yml')
        FileUtils.mkdir_p(output_path)

        File.open(output_file, 'w:utf-8') do |output|
          output.write(
            TwitterCldr::Utils::YAML.dump(
              TwitterCldr::Utils.deep_symbolize_keys(validity_data: validity_data),
              use_natural_symbols: true
            )
          )
        end
      end

      private

      def validity_data
        {
          languages: validity_data_for('language', casing: :downcase),
          scripts:   validity_data_for('script', casing: :capitalize),
          regions:   validity_data_for('region', casing: :upcase),
          variants:  validity_data_for('variant', casing: :upcase)
        }
      end

      def validity_data_for(type, casing:)
        doc = Nokogiri.XML(File.read(File.join(validity_path, "#{type}.xml")))

        doc.xpath("//supplementalData/idValidity/id[@type='#{type}']").each_with_object({}) do |data, ret|
          id_status = data.attribute('idStatus').value
          ret[id_status] = data.text.split(' ').flat_map do |datum|
            expand_string_range(datum.strip).map do |str|
              str.send(casing)
            end
          end
        end
      end

      def expand_string_range(str)
        return [str] unless str.include?('~')

        from, to = str.split('~')
        prefix = from[0...(from.size - to.size)]
        from = from[-(to.size)..-1]

        expand_string_range_each(from, to, 0).map do |s|
          "#{prefix}#{s}"
        end
      end

      def expand_string_range_each(from, to, i, &block)
        return to_enum(__method__, from, to, i) unless block

        if i == from.size
          yield from
          return
        end

        (from[i]..to[i]).each do |c|
          current = "#{from[0...i]}#{c}#{from[(i + 1)..-1]}"
          expand_string_range_each(current, to, i + 1, &block)
        end
      end

      def validity_path
        File.join(requirements[:cldr].common_path, 'validity')
      end

      def output_path
        params.fetch(:output_path)
      end
    end

  end
end
