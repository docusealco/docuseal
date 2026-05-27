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

    class CalendarsImporter < Importer

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
          GregorianCalendar.new(ancestor_locale, requirements[:cldr]).to_h
        end

        output_file = File.join(output_path, locale.to_s, 'calendars.yml')
        FileUtils.mkdir_p(File.dirname(output_file))

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


    class GregorianCalendar
      ERA_TAGS = ['eraNames', 'eraAbbr', 'eraNarrow'].freeze

      attr_reader :locale, :cldr_req

      def initialize(locale, cldr_req)
        @locale = locale
        @cldr_req = cldr_req
      end

      def to_h
        {
          calendars: {
            gregorian: {
              days:     contexts('day'),
              months:   contexts('month'),
              eras:     eras,
              quarters: contexts('quarter'),
              periods:  contexts('dayPeriod', group: "alt"),
              fields:   fields,
              formats: {
                date:     formats('date'),
                time:     formats('time'),
                datetime: formats('dateTime')
              },
              additional_formats: additional_formats
            }
          }
        }
      end

      private

      def calendar
        @calendar ||= docset.xpath('//ldml/dates/calendars/calendar[@type="gregorian"]').first
      end

      def contexts(kind, options = {})
        return {} unless calendar

        dtd.find_attr("#{kind}Context", 'type').values.each_with_object({}) do |context, result|
          node = calendar.xpath("#{kind}s/#{kind}Context[@type='#{context}']").first
          next unless node

          result[context] = widths(node, kind, context, options)
        end
      end

      def widths(node, kind, context, options = {})
        dtd.find_attr("#{kind}Width", 'type').values.each_with_object({}) do |width, result|
          width_node = node.xpath("#{kind}Width[@type='#{width}']").first
          next unless width_node

          result[width] = elements(width_node, kind, context, width, options)
        end
      end

      def elements(node, kind, context, width, options = {})
        node.xpath(kind).each_with_object({}) do |node, result|
          key = node.attribute('type').value
          key = key =~ /^\d*$/ ? key.to_i : key.to_sym

          if options[:group] && found_group = node.attribute(options[:group])
            result[found_group.value] ||= {}
            result[found_group.value][key] = node.content
          else
            result[key] = node.content
          end
        end
      end

      def periods
        am = calendar.xpath("am").first
        pm = calendar.xpath("pm").first

        {}.tap do |result|
          result[:am] = am.content if am
          result[:pm] = pm.content if pm
        end
      end

      def eras
        return {} unless calendar

        ERA_TAGS.each_with_object({}) do |era_tag, result|
          key  = era_tag.gsub('era', '').gsub(/s$/, '').downcase.to_sym
          path = "eras/#{era_tag}"

          result[key] = dtd.find_attr('era', 'type').values.each_with_object({}) do |type, ret|
            node = calendar.xpath("#{path}/era[@type='#{type}' and @alt='variant']").first ||
              calendar.xpath("#{path}/era[@type='#{type}']").first
            ret[type] = node.content if node
            ret
          end
        end
      end

      def formats(type)
        return {} unless calendar

        formats = dtd.find_attr("#{type}FormatLength", 'type').values.each_with_object({}) do |format_length, result|
          node = calendar.xpath("#{type}Formats/#{type}FormatLength[@type='#{format_length}']").first
          result[format_length] = pattern(node, type) if node
        end

        if default = default_format(type)
          formats = default.merge(formats)
        end

        formats
      end

      def additional_formats
        return {} unless calendar

        calendar.xpath("dateTimeFormats/availableFormats/dateFormatItem").each_with_object({}) do |date_format_item, result|
          result[date_format_item.attribute("id").value] = date_format_item.content
        end
      end

      def default_format(type)
        if node = calendar.xpath("#{type}Formats/default").first
          key = node.attribute('choice').value.to_sym
          { default: :"calendars.gregorian.formats.#{type.downcase}.#{key}" }
        end
      end

      def pattern(node, type)
        node.xpath("#{type}Format/pattern").each_with_object({}) do |node, result|
          pattern = node.content
          pattern = pattern.gsub('{0}', '{{time}}').gsub('{1}', '{{date}}') if type == 'dateTime'
          result[:pattern] = pattern
        end
      end

      def fields
        dtd.find_attr('field', 'type').values.each_with_object({}) do |field, result|
          node = docset.xpath("//ldml/dates/fields/field[@type='#{field}']").first
          name = node.xpath('displayName').first
          result[field] = name.content if name
        end
      end

      def docset
        @docset ||= cldr_req.docset(cldr_main_path, locale)
      end

      def cldr_main_path
        @cldr_main_path ||= File.join(cldr_req.common_path, 'main')
      end

      def dtd
        cldr_req.dtd
      end

    end

  end
end
