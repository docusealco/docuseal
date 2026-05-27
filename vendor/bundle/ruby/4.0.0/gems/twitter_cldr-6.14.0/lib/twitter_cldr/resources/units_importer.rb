# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'nokogiri'
require 'fileutils'
require 'parallel'
require 'etc'
require 'set'

module TwitterCldr
  module Resources

    class UnitsImporter < Importer

      requirement :cldr, Versions.cldr_version
      output_path 'locales'
      locales TwitterCldr.supported_locales
      ruby_engine :mri

      private

      def execute
        locales = Set.new

        finish = -> (locale, *) do
          locales.add(locale)
          STDOUT.write "\rImported #{locale}, #{locales.size} of #{params[:locales].size} total"
        end

        Parallel.each(params[:locales], in_processes: Etc.nprocessors, finish: finish) do |locale|
          import_locale(locale)
          locales << locale
        end
      end

      def import_locale(locale)
        data = requirements[:cldr].build_data(locale) do |ancestor_locale|
          Units.new(ancestor_locale, requirements[:cldr]).to_h
        end

        output_file = File.join(output_path, locale.to_s, 'units.yml')

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

    end


    class Units
      attr_reader :locale, :cldr_req

      def initialize(locale, cldr_req)
        @locale = locale
        @cldr_req = cldr_req
      end

      def to_h
        {
          units: {
            unitLength: unit_length,
            durationUnit: duration_unit
          }
        }
      end

      private

      def unit_length
        doc.xpath('//ldml/units/unitLength').each_with_object({}) do |node, result|
          type = node.attribute('type').value.to_sym
          result[type] = units(node)
        end
      end

      def resolve_unit_node(root, unit_node)
        alias_node = unit_node.xpath('alias')[0]
        return unit_node unless alias_node

        # follow aliases so we can fully expand them
        alias_type = alias_node.attribute('path').value[/@type='([\w-]+)'/, 1]
        found_node = root.xpath("unit[@type='#{alias_type}']")
        resolve_unit_node(root, found_node)
      end

      def units(node)
        node.xpath('unit').each_with_object({}) do |unit_node, result|
          unit_node = resolve_unit_node(node, unit_node)
          type = unit_node.attribute('type').value.to_sym
          found_unit = unit(unit_node)
          result[type] = found_unit unless found_unit.empty?
        end
      end

      def unit(node)
        node.xpath('unitPattern').each_with_object({}) do |node, result|
          count = node.attribute('count') ? node.attribute('count').value.to_sym : :one
          result[count] = node.content
        end
      end

      def duration_unit
        doc.xpath('//ldml/units/durationUnit').each_with_object({}) do |node, result|
          result[node.attribute('type').value.to_sym] = node.xpath('durationUnitPattern').first.content
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
