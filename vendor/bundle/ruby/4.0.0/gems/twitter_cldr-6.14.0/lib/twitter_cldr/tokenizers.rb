# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Tokenizers
    autoload :Base,                         'twitter_cldr/tokenizers/base'
    autoload :Token,                        'twitter_cldr/tokenizers/token'
    autoload :Tokenizer,                    'twitter_cldr/tokenizers/tokenizer'
    autoload :TokenRecognizer,              'twitter_cldr/tokenizers/tokenizer'
    autoload :PatternTokenizer,             'twitter_cldr/tokenizers/pattern_tokenizer'
    autoload :DateTimeTokenizer,            'twitter_cldr/tokenizers/calendars/date_time_tokenizer'
    autoload :DateTokenizer,                'twitter_cldr/tokenizers/calendars/date_tokenizer'
    autoload :TimeTokenizer,                'twitter_cldr/tokenizers/calendars/time_tokenizer'
    autoload :NumberTokenizer,              'twitter_cldr/tokenizers/numbers/number_tokenizer'
    autoload :RbnfTokenizer,                'twitter_cldr/tokenizers/numbers/rbnf_tokenizer'
    autoload :TimespanTokenizer,            'twitter_cldr/tokenizers/calendars/timespan_tokenizer'
    autoload :UnicodeRegexTokenizer,        'twitter_cldr/tokenizers/unicode_regex/unicode_regex_tokenizer'
    autoload :SegmentationTokenizer,        'twitter_cldr/tokenizers/segmentation/segmentation_tokenizer'
  end
end