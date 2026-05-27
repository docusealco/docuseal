# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'nokogiri'

module TwitterCldr
  module Resources

    class ParentLocalesImporter < Importer

      requirement :cldr, Versions.cldr_version
      output_path 'shared'
      ruby_engine :mri

      private

      def execute
        output_file = File.join(output_path, 'parent_locales.yml')
        File.write(output_file, YAML.dump(parent_locales))
      end

      def parent_locales
        @parent_locales ||= supplemental_data.xpath('//parentLocales/parentLocale').each_with_object({}) do |node, ret|
          parent = node.attr('parent')
          locales = node.attr('locales').split(' ')

          locales.each do |locale|
            ret[locale] = parent
          end
        end
      end

      def output_path
        params.fetch(:output_path)
      end

      def supplemental_data
        @supplemental_data ||= Nokogiri.XML(
          File.read(
            File.join(
              requirements[:cldr].common_path,
              'supplemental',
              'supplementalData.xml'
            )
          )
        )
      end

    end

  end
end
