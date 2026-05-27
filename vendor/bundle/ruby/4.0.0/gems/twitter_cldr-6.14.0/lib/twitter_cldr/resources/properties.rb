# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources
    module Properties

      autoload :PropertyImporter,                        'twitter_cldr/resources/properties/property_importer'
      autoload :AgePropertyImporter,                     'twitter_cldr/resources/properties/age_property_importer'
      autoload :ArabicShapingPropertyImporter,           'twitter_cldr/resources/properties/arabic_shaping_property_importer'
      autoload :BidiBracketsPropertyImporter,            'twitter_cldr/resources/properties/bidi_brackets_property_importer'
      autoload :BlocksPropertyImporter,                  'twitter_cldr/resources/properties/blocks_property_importer'
      autoload :DerivedCorePropertiesImporter,           'twitter_cldr/resources/properties/derived_core_properties_importer'
      autoload :EastAsianWidthPropertyImporter,          'twitter_cldr/resources/properties/east_asian_width_property_importer'
      autoload :EmojiImporter,                           'twitter_cldr/resources/properties/emoji_importer'
      autoload :GraphemeBreakPropertyImporter,           'twitter_cldr/resources/properties/grapheme_break_property_importer'
      autoload :HangulSyllableTypePropertyImporter,      'twitter_cldr/resources/properties/hangul_syllable_type_property_importer'
      autoload :IndicPositionalCategoryPropertyImporter, 'twitter_cldr/resources/properties/indic_positional_category_property_importer'
      autoload :IndicSyllabicCategoryPropertyImporter,   'twitter_cldr/resources/properties/indic_syllabic_category_property_importer'
      autoload :JamoPropertyImporter,                    'twitter_cldr/resources/properties/jamo_property_importer'
      autoload :LineBreakPropertyImporter,               'twitter_cldr/resources/properties/line_break_property_importer'
      autoload :PropListImporter,                        'twitter_cldr/resources/properties/prop_list_importer'
      autoload :ScriptExtensionsPropertyImporter,        'twitter_cldr/resources/properties/script_extensions_property_importer'
      autoload :ScriptPropertyImporter,                  'twitter_cldr/resources/properties/script_property_importer'
      autoload :SentenceBreakPropertyImporter,           'twitter_cldr/resources/properties/sentence_break_property_importer'
      autoload :UnicodeDataPropertiesImporter,           'twitter_cldr/resources/properties/unicode_data_properties_importer'
      autoload :WordBreakPropertyImporter,               'twitter_cldr/resources/properties/word_break_property_importer'

    end
  end
end
