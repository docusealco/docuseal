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

    class TimezonesImporter < Importer

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

        puts ''
      end

      def import_locale(locale)
        data = requirements[:cldr].build_data(locale) do |ancestor_locale|
          TimezoneData.new(ancestor_locale, requirements[:cldr]).to_h
        end

        data = remove_empties(data)
        output_file = File.join(output_path, locale.to_s, 'timezones.yml')

        File.open(output_file, 'w:utf-8') do |output|
          output.write(
            TwitterCldr::Utils::YAML.dump(
              TwitterCldr::Utils.deep_symbolize_keys(locale => data),
              use_natural_symbols: true
            )
          )
        end
      end

      # "If a given short metazone form is known NOT to be understood in a
      # given locale and the parent locale has this value such that it would
      # normally be inherited, the inheritance of this value can be explicitly
      # disabled by use of the 'no inheritance marker' as the value, which is
      # 3 simultaneous empty set characters ( U+2205 )."
      #
      # http://www.unicode.org/reports/tr35/tr35-dates.html#Metazone_Names
      #
      def remove_empties(h)
        h.delete_if do |_k, v|
          v == '∅∅∅'
        end

        h.each_pair do |_k, v|
          remove_empties(v) if v.is_a?(Hash)
        end

        h.delete_if do |_k, v|
          v.is_a?(Hash) && v.empty?
        end
      end

      def output_path
        params.fetch(:output_path)
      end


      class TimezoneData
        attr_reader :locale, :cldr_req

        def initialize(locale, cldr_req)
          @locale = locale
          @cldr_req = cldr_req
        end

        def to_h
          {
            formats: formats,
            timezones: timezones,
            metazones: metazones
          }
        end

        private

        def formats
          @formats ||= doc.xpath('ldml/dates/timeZoneNames/*').inject({}) do |result, format|
            if format.name.end_with?('Format')
              next if unconfirmed_draft?(format)

              underscored_name = format.name.gsub(/([a-z])([A-Z])/, '\1_\2').downcase + 's'
              result[underscored_name] ||= {}

              type = if (type_attr = format.attribute('type'))
                type_attr.value
              else
                :generic
              end

              result[underscored_name][type] = format.text
            end

            result
          end
        end

        def timezones
          @timezones ||= doc.xpath('ldml/dates/timeZoneNames/zone').inject({}) do |result, zone|
            type = zone.attr('type').to_sym
            result[type] = {}
            long = nodes_to_hash(zone.xpath('long/*'))
            result[type][:long] = long unless long.empty?
            short = nodes_to_hash(zone.xpath('short/*'))
            result[type][:short] = short unless short.empty?
            city = zone.xpath('exemplarCity').first
            if city && !unconfirmed_draft?(city) && !secondary?(city)
              result[type][:city] = city.content
            end
            result
          end
        end

        def metazones
          @metazones ||= doc.xpath('ldml/dates/timeZoneNames/metazone').inject({}) do |result, zone|
            type = zone.attr('type').to_sym
            result[type] = {}
            long = nodes_to_hash(zone.xpath('long/*'))
            result[type][:long] = long unless long.empty?
            short = nodes_to_hash(zone.xpath('short/*'))
            result[type][:short] = short unless short.empty?
            result
          end
        end

        def nodes_to_hash(nodes)
          nodes.inject({}) do |result, node|
            unless cldr_req.draft?(node)
              result[node.name.to_sym] = node.content
            end

            result
          end
        end

        def unconfirmed_draft?(node)
          node &&
            node.attributes['draft'] &&
            node.attributes['draft'].value == 'unconfirmed'
        end

        def secondary?(node)
          node &&
            node.attributes['alt'] &&
            node.attributes['alt'].value == 'secondary'
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
