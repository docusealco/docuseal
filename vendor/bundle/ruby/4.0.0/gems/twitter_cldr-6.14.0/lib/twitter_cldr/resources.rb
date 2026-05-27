# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources
    autoload :AliasesImporter,                'twitter_cldr/resources/aliases_importer'
    autoload :Bcp47TimezoneMetadataImporter,  'twitter_cldr/resources/bcp47_timezone_metadata_importer'
    autoload :BidiTestImporter,               'twitter_cldr/resources/bidi_test_importer'
    autoload :CalendarsImporter,              'twitter_cldr/resources/calendars_importer'
    autoload :CasefolderClassGenerator,       'twitter_cldr/resources/casefolder_class_generator'
    autoload :CldrDataBuilder,                'twitter_cldr/resources/cldr_data_builder'
    autoload :CldrDocumentSet,                'twitter_cldr/resources/cldr_document_set'
    autoload :CldrDTD,                        'twitter_cldr/resources/cldr_dtd'
    autoload :CldrLocale,                     'twitter_cldr/resources/cldr_locale'
    autoload :CollationTestsImporter,         'twitter_cldr/resources/collation_tests_importer'
    autoload :CollationTriesImporter,         'twitter_cldr/resources/collation_tries_importer'
    autoload :CurrencySymbolsImporter,        'twitter_cldr/resources/currency_symbols_importer'
    autoload :DayPeriodRulesImporter,         'twitter_cldr/resources/day_period_rules_importer'
    autoload :HyphenationImporter,            'twitter_cldr/resources/hyphenation_importer'
    autoload :Importer,                       'twitter_cldr/resources/importer'
    autoload :ImportResolver,                 'twitter_cldr/resources/import_resolver'
    autoload :LanguageCodesImporter,          'twitter_cldr/resources/language_codes_importer'
    autoload :ListFormatsImporter,            'twitter_cldr/resources/list_formats_importer'
    autoload :Loader,                         'twitter_cldr/resources/loader'
    autoload :LocalesResourcesImporter,       'twitter_cldr/resources/locales_resources_importer'
    autoload :NumberFormatsImporter,          'twitter_cldr/resources/number_formats_importer'
    autoload :ParentLocalesImporter,          'twitter_cldr/resources/parent_locales_importer'
    autoload :PostalCodesImporter,            'twitter_cldr/resources/postal_codes_importer'
    autoload :Properties,                     'twitter_cldr/resources/properties'
    autoload :ResourceLoadError,              'twitter_cldr/resources/loader'
    autoload :SegmentDictionariesImporter,    'twitter_cldr/resources/segment_dictionaries_importer'
    autoload :SegmentRulesImporter,           'twitter_cldr/resources/segment_rules_importer'
    autoload :SegmentTestsImporter,           'twitter_cldr/resources/segment_tests_importer'
    autoload :RbnfTestImporter,               'twitter_cldr/resources/rbnf_test_importer'
    autoload :ReadmeRenderer,                 'twitter_cldr/resources/readme_renderer'
    autoload :RegexpAstGenerator,             'twitter_cldr/resources/regexp_ast_generator'
    autoload :Requirements,                   'twitter_cldr/resources/requirements'
    autoload :TailoringImporter,              'twitter_cldr/resources/tailoring_importer'
    autoload :TerritoriesImporter,            'twitter_cldr/resources/territories_importer'
    autoload :TimezonesImporter,              'twitter_cldr/resources/timezones_importer'
    autoload :TimezoneRegionsImporter,        'twitter_cldr/resources/timezone_regions_importer'
    autoload :TimezoneTestsImporter,          'twitter_cldr/resources/timezone_tests_importer'
    autoload :TransformTestsImporter,         'twitter_cldr/resources/transform_tests_importer'
    autoload :TransformsImporter,             'twitter_cldr/resources/transforms_importer'
    autoload :UnicodeDataImporter,            'twitter_cldr/resources/unicode_data_importer'
    autoload :UnicodeFileParser,              'twitter_cldr/resources/unicode_file_parser'
    autoload :UnicodePropertyAliasesImporter, 'twitter_cldr/resources/unicode_property_aliases_importer'
    autoload :UnitsImporter,                  'twitter_cldr/resources/units_importer'
    autoload :ValidityDataImporter,           'twitter_cldr/resources/validity_data_importer'

    class << self
      # these importer class methods aren't constants in order to avoid loading
      # all the classes when the library is required

      def standard_importer_classes
        @standard_importer_classes ||= [
          AliasesImporter,
          Bcp47TimezoneMetadataImporter,
          BidiTestImporter,
          ValidityDataImporter,
          UnicodePropertyAliasesImporter,
          CalendarsImporter,
          CasefolderClassGenerator,
          CollationTestsImporter,
          CollationTriesImporter,
          CurrencySymbolsImporter,
          DayPeriodRulesImporter,
          HyphenationImporter,
          LanguageCodesImporter,
          ListFormatsImporter,
          LocalesResourcesImporter,
          NumberFormatsImporter,
          ParentLocalesImporter,
          PostalCodesImporter,
          RbnfTestImporter,
          SegmentDictionariesImporter,
          SegmentRulesImporter,
          SegmentTestsImporter,
          TailoringImporter,
          TerritoriesImporter,
          TimezonesImporter,
          TimezoneRegionsImporter,
          TimezoneTestsImporter,
          TransformTestsImporter,
          TransformsImporter,
          UnicodeDataImporter,
          UnitsImporter
        ]
      end

      def property_importer_classes
        @property_importer_classes ||= [
          Properties::AgePropertyImporter,
          Properties::ArabicShapingPropertyImporter,
          Properties::BidiBracketsPropertyImporter,
          Properties::BlocksPropertyImporter,
          Properties::DerivedCorePropertiesImporter,
          Properties::EastAsianWidthPropertyImporter,
          Properties::EmojiImporter,
          Properties::GraphemeBreakPropertyImporter,
          Properties::HangulSyllableTypePropertyImporter,
          Properties::IndicPositionalCategoryPropertyImporter,
          Properties::IndicSyllabicCategoryPropertyImporter,
          Properties::JamoPropertyImporter,
          Properties::LineBreakPropertyImporter,
          Properties::PropListImporter,
          Properties::ScriptExtensionsPropertyImporter,
          Properties::ScriptPropertyImporter,
          Properties::SentenceBreakPropertyImporter,
          Properties::UnicodeDataPropertiesImporter,
          Properties::WordBreakPropertyImporter
        ]
      end

      def importer_classes
        @importer_classes ||=
          standard_importer_classes +
          property_importer_classes
      end

      def importer_classes_for_ruby_engine
        engine = case RUBY_ENGINE
          when 'ruby' then :mri
          when 'jruby' then :jruby
          else
            raise "Unsupported RUBY_ENGINE '#{RUBY_ENGINE}'"
        end

        importer_classes.select do |klass|
          klass.default_params[:ruby_engine] == engine
        end
      end

      def locale_based_importer_classes_for_ruby_engine
        importer_classes_for_ruby_engine.select do |klass|
          !!klass.default_params[:locales]
        end
      end
    end
  end
end
