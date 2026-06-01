# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'nokogiri'
require 'fileutils'

module TwitterCldr
  module Resources

    class DayPeriodRulesImporter < Importer

      requirement :cldr, Versions.cldr_version
      requirement :dependency, [
        ValidityDataImporter, UnicodePropertyAliasesImporter, LocalesResourcesImporter
      ]

      output_path 'locales'
      locales TwitterCldr.supported_locales
      ruby_engine :mri

      private

      def execute
        merged_rule_sets.each do |locale, rules|
          output_file = File.join(output_path, locale, 'day_periods.yml')
          FileUtils.mkdir_p(File.dirname(output_file))

          File.open(output_file, 'w:utf-8') do |output|
            output.write(
              TwitterCldr::Utils::YAML.dump(
                TwitterCldr::Utils.deep_symbolize_keys(locale => rules),
                use_natural_symbols: true
              )
            )
          end
        end
      end

      def merged_rule_sets
        {}.tap do |results|
          params[:locales].each do |locale_sym|
            locale = TwitterCldr::Shared::Locale.parse(locale_sym.to_s)
            results[locale.to_s('-')] ||= {}

            raw_rule_sets.each do |rule_set_name, locale_data|
              rules = locale.maximize.permutations.inject({}) do |ret, locale_perm|
                ret.merge(locale_data.fetch(locale_perm.to_sym, {}))
              end

              rules.merge!(locale_data[:root])
              results[locale.to_s('-')][rule_set_name] = rules
            end
          end
        end
      end

      def raw_rule_sets
        {}.tap do |resulting_rule_sets|
          doc.xpath('//supplementalData/dayPeriodRuleSet').each do |rule_set_node|
            rule_set_type = rule_set_node.attribute('type')&.value || :default
            resulting_rule_sets[rule_set_type.to_sym] = rule_set_from(rule_set_node)
          end
        end
      end

      def rule_set_from(rule_set_node)
        {}.tap do |rule_set|
          rule_set_node.xpath('dayPeriodRules').each do |rules_node|
            locales = rules_node.attribute('locales').value
              .split(' ')
              .map { |loc| loc.strip.to_sym }

            locales.each do |locale|
              rule_set[locale] = rules_from(rules_node)
            end
          end
        end
      end

      def rules_from(rules_node)
        rules_node.xpath('dayPeriodRule').each_with_object({}) do |rule, rules|
          type = rule.attribute('type').value

          if at = rule.attribute('at')&.value
            rules[type] = { at: parse_time(at) }
          else
            from = rule.attribute('from').value
            before = rule.attribute('before').value
            rules[type] = {
              from: parse_time(from), before: parse_time(before)
            }
          end
        end
      end

      def parse_time(time_str)
        hour, min = time_str.split(':')
        { hour: hour.to_i, min: min.to_i }
      end

      def input_file
        @input_file ||= File.join(
          requirements[:cldr].common_path, 'supplemental', 'dayPeriods.xml'
        )
      end

      def output_path
        params.fetch(:output_path)
      end

      def doc
        @doc ||= Nokogiri.XML(File.read(input_file))
      end

      def cldr_main_path
        @cldr_main_path ||= File.join(cldr_req.common_path, 'main')
      end

    end

  end
end
