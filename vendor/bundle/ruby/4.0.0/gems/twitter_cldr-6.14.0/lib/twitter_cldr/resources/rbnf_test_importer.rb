# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'fileutils'

module TwitterCldr
  module Resources

    # This class should be used with JRuby in 1.9 mode
    class RbnfTestImporter < Importer
      # These don't have much of a pattern, just trying to get
      # a wide range of different possibilities.
      TEST_NUMBERS = [
        [-1_141, -1_142, -1_143],
        [-100, -75, -50, -24],
        (0..100).to_a,
        [321, 322, 323, 1_141, 1_142, 1_143, 10_311, 138_400]
        # [41.0, 5.22, 8.90, 555.1212, -14.90, -999.701]  # decimals really aren't supported yet
      ].flatten

      requirement :icu, Versions.icu_version
      output_path File.join(TwitterCldr::SPEC_DIR, 'formatters', 'numbers', 'rbnf', 'locales')
      locales TwitterCldr.supported_locales
      ruby_engine :jruby

      def execute
        locales.each do |locale|
          locale = locale.to_s
          ulocale = ulocale_class.new(locale)
          file = output_file_for(locale)
          FileUtils.mkdir_p(File.dirname(file))
          File.open(file, "w+") do |w|
            w.write(YAML.dump(import_locale(ulocale)))
          end
        end
      end

      private

      def locales
        @locales ||= params.fetch(:locales).select do |locale|
          TwitterCldr::Formatters::Rbnf::RbnfFormatter.supported_locale?(locale)
        end
      end

      def formatter_class
        @formatter_class ||= requirements[:icu].get_class('com.ibm.icu.text.RuleBasedNumberFormat')
      end

      def ulocale_class
        @ulocale_class ||= requirements[:icu].get_class('com.ibm.icu.util.ULocale')
      end

      def import_locale(ulocale)
        groupings.inject({}) do |grouping_ret, grouping|
          formatter = formatter_class.new(ulocale, grouping)
          grouping_name = get_grouping_display_name(grouping)
          grouping_ret[grouping_name] = formatter.getRuleSetNames.inject({}) do |ruleset_ret, ruleset_name|
            ruleset_display_name = formatter.getRuleSetDisplayName(ruleset_name, ulocale)
            ruleset_display_name = clean_up_name(ruleset_display_name)
            ruleset_ret[ruleset_display_name] = import_ruleset(ulocale.toString, formatter, ruleset_name)
            ruleset_ret
          end
          grouping_ret
        end
      end

      def groupings
        @groupings ||= [
          formatter_class::SPELLOUT,
          formatter_class::ORDINAL,
          formatter_class::DURATION
        ]
      end

      def clean_up_name(name)
        name
          .gsub(/[^\w-]/, '-')
          .gsub('GREEKNUMERALMAJUSCULES', 'GreekNumeralMajuscules')
      end

      def import_ruleset(locale, formatter, ruleset_name)
        TEST_NUMBERS.each_with_object({}) do |num, ret|
          ret[num] = formatter.format(num, ruleset_name)
        end
      end

      def output_file_for(locale)
        File.join(params.fetch(:output_path), locale, 'rbnf_test.yml')
      end

      def get_grouping_display_name(grouping)
        case grouping
          when formatter_class::SPELLOUT
            'SpelloutRules'
          when formatter_class::ORDINAL
            'OrdinalRules'
          when formatter_class::DURATION
            'DurationRules'
        end
      end

    end
  end
end
