# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'nokogiri'
require 'fileutils'

module TwitterCldr
  module Resources

    class Bcp47TimezoneMetadataImporter < Importer

      requirement :cldr, Versions.cldr_version
      output_path 'shared'
      ruby_engine :mri

      private

      def execute
        File.open(output_file, 'w:utf-8') do |output|
          output.write(
            TwitterCldr::Utils::YAML.dump(
              TwitterCldr::Utils.deep_symbolize_keys(metadata),
              use_natural_symbols: true
            )
          )
        end
      end

      def metadata
        { aliases: {}, short_names: {} }.tap do |result|
          doc.xpath("//ldmlBCP47/keyword/key[@name='tz']/type").each do |node|
            alias_node = node.attribute('alias')
            next unless alias_node

            alias_list = alias_node.value.split(' ')
            name = node.attribute('name').value

            alias_list.each do |a|
              result[:short_names][a] = name
            end

            next if alias_list.size <= 1

            alias_list[1..-1].each do |a|
              result[:aliases][a] = alias_list[0]
            end
          end
        end
      end

      def doc
        @doc ||= Nokogiri::XML(File.read(input_file))
      end

      def input_file
        @input_file ||= File.join(
          requirements[:cldr].common_path, 'bcp47', 'timezone.xml'
        )
      end

      def output_file
        @output_file ||= File.join(output_path, 'bcp47_timezone_metadata.yml')
      end

      def output_path
        params.fetch(:output_path)
      end

    end
  end
end
