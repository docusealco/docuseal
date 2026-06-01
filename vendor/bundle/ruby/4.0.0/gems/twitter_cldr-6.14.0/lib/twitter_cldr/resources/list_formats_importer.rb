# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'nokogiri'
require 'parallel'
require 'etc'
require 'set'

module TwitterCldr
  module Resources

    class ListFormatsImporter < Importer

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

        puts
      end

      def import_locale(locale)
        # The merging that happens here works at the listPatternPart level of granularity.
        # In other words, a missing part will be filled in by any part with the same key
        # in the locale's ancestor chain. The raw CLDR data contains the inheritance marker
        # (i.e. "↑↑↑") for listPatterns that are missing parts, but the expanded data we
        # get in the downloadable CLDR zip file doesn't include them or the inherited data,
        # making it impossible for TwitterCLDR to know how it should handle missing keys.
        # I believe whatever massage tool the CLDR maintainers use to generate the final
        # data set doesn't take aliases into account, which explains the holes in the data.
        # By allowing individual listPatternParts to be populated by data from ancestor
        # locales, we fill in any missing parts at the minor risk of being slightly wrong
        # when formatting lists. In my opinion, it's far better to produce a slightly wrong
        # string than to error or produce an entirely empty string.
        data = requirements[:cldr].build_data(locale) do |ancestor_locale|
          ListFormats.new(ancestor_locale, requirements[:cldr]).to_h
        end

        output_file = File.join(output_path, locale.to_s, 'lists.yml')

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


    class ListFormats

      attr_reader :locale, :cldr_req

      def initialize(locale, cldr_req)
        @locale = locale
        @cldr_req = cldr_req
      end

      def to_h
        { lists: lists }
      end

      def lists
        doc.xpath('//ldml/listPatterns/listPattern').each_with_object({}) do |pattern_node, pattern_result|
          pattern_type = if attribute = pattern_node.attribute('type')
            attribute.value.to_sym
          else
            :default
          end

          pattern_node = pattern_for(pattern_type)

          pattern_result[pattern_type] = pattern_node.xpath('listPatternPart').each_with_object({}) do |type_node, type_result|
            type_result[type_node.attribute('type').value.to_sym] = type_node.content
          end
        end
      end

      def pattern_for(type)
        xpath = xpath_for(type)
        pattern_node = doc.xpath(xpath)[0]
        alias_node = pattern_node.xpath('alias')[0]

        if alias_node
          alias_type = alias_node.attribute('path').value[/@type='([\w-]+)'/, 1] || :default
          # follow aliases so we can fully expand them
          pattern_node = pattern_for(alias_type)
        end

        pattern_node
      end

      def xpath_for(type)
        if type == :default
          '//ldml/listPatterns/listPattern[not(@type)]'
        else
          "//ldml/listPatterns/listPattern[@type='#{type}']"
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
