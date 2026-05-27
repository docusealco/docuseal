# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    autoload :BrahmicBreakEngine,    'twitter_cldr/segmentation/brahmic_break_engine'
    autoload :BreakIterator,         'twitter_cldr/segmentation/break_iterator'
    autoload :BurmeseBreakEngine,    'twitter_cldr/segmentation/burmese_break_engine'
    autoload :CategoryTable,         'twitter_cldr/segmentation/category_table'
    autoload :CjBreakEngine,         'twitter_cldr/segmentation/cj_break_engine'
    autoload :Cursor,                'twitter_cldr/segmentation/cursor'
    autoload :Dictionary,            'twitter_cldr/segmentation/dictionary'
    autoload :DictionaryBreakEngine, 'twitter_cldr/segmentation/dictionary_break_engine'
    autoload :KhmerBreakEngine,      'twitter_cldr/segmentation/khmer_break_engine'
    autoload :KoreanBreakEngine,     'twitter_cldr/segmentation/korean_break_engine'
    autoload :LaoBreakEngine,        'twitter_cldr/segmentation/lao_break_engine'
    autoload :LineIterator,          'twitter_cldr/segmentation/line_iterator'
    autoload :Metadata,              'twitter_cldr/segmentation/metadata'
    autoload :NullSuppressions,      'twitter_cldr/segmentation/null_suppressions'
    autoload :PossibleWord,          'twitter_cldr/segmentation/possible_word'
    autoload :PossibleWordList,      'twitter_cldr/segmentation/possible_word_list'
    autoload :RuleSet,               'twitter_cldr/segmentation/rule_set'
    autoload :SegmentIterator,       'twitter_cldr/segmentation/segment_iterator'
    autoload :StateMachine,          'twitter_cldr/segmentation/state_machine'
    autoload :StateTable,            'twitter_cldr/segmentation/state_table'
    autoload :StatusTable,           'twitter_cldr/segmentation/status_table'
    autoload :Suppressions,          'twitter_cldr/segmentation/suppressions'
    autoload :ThaiBreakEngine,       'twitter_cldr/segmentation/thai_break_engine'
    autoload :UnhandledBreakEngine,  'twitter_cldr/segmentation/unhandled_break_engine'
    autoload :WordIterator,          'twitter_cldr/segmentation/word_iterator'
  end
end
