# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'nokogiri'

module TwitterCldr
  module Resources

    class TerritoriesImporter < Importer

      requirement :cldr, Versions.cldr_version
      output_path 'locales'
      locales TwitterCldr.supported_locales
      ruby_engine :mri

      Territories = TwitterCldr::Shared::Territories

      private

      def execute
        params[:locales].each do |locale|
          import_locale(locale)
        end
      end

      def import_locale(locale)
        data = requirements[:cldr].build_data(locale) do |ancestor_locale|
          TerritoryData.new(ancestor_locale, requirements[:cldr]).to_h
        end

        output_file = File.join(output_path, locale.to_s, 'territories.yml')

        File.open(output_file, 'w:utf-8') do |output|
          output.write(
            TwitterCldr::Utils::YAML.dump(
              TwitterCldr::Utils.deep_symbolize_keys(locale => data),
              use_natural_symbols: true
            )
          )
        end
      end

      def output_path
        params.fetch(:output_path)
      end


      class TerritoryData
        attr_reader :locale, :cldr_req

        def initialize(locale, cldr_req)
          @locale = locale
          @cldr_req = cldr_req
        end

        def to_h
          { territories: Territories.deep_normalize_territory_code_keys(territories) }
        end

        private

        def territories
          doc.xpath('//ldml/localeDisplayNames/territories/territory').inject({}) do |result, node|
            unless cldr_req.draft?(node) || cldr_req.alt?(node)
              result[node.attribute('type').value.downcase.to_sym] = node.content
            end

            result
          end
        end

        def doc
          @doc ||= begin
            locale_fs = locale.to_s.gsub('-', '_')
            Nokogiri.XML(File.read(File.join(cldr_main_path, "#{locale_fs}.xml")))
          end
        end

        def cldr_main_path
          @cldr_main_path ||= File.join(cldr_req.common_path, 'main')
        end
      end

    end
  end
end
