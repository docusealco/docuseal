# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Tokenizers
    class RbnfTokenizer

      def tokenize(pattern)
        PatternTokenizer.new(nil, tokenizer).tokenize(pattern)
      end

      private

      def tokenizer
        @tokenizer ||= begin
          recognizers = [
            # special rule descriptors
            TokenRecognizer.new(:negative, /-x/),
            TokenRecognizer.new(:improper_fraction, /x\.x/),
            TokenRecognizer.new(:proper_fraction, /0\.x/),
            TokenRecognizer.new(:master, /x\.0/),

            # normal rule descriptors
            TokenRecognizer.new(:equals, /=/),
            TokenRecognizer.new(:rule, /%%?[[:word:]-]+/),  # i.e. %spellout-numbering, %%2d-year
            TokenRecognizer.new(:right_arrow, />/),
            TokenRecognizer.new(:left_arrow, /</),
            TokenRecognizer.new(:open_bracket, /\[/),
            TokenRecognizer.new(:close_bracket, /\]/),
            TokenRecognizer.new(:decimal, /[0#][0#,\.]*/),
            TokenRecognizer.new(:plural, /\$\(.*\)\$/),

            # ending
            TokenRecognizer.new(:semicolon, /;/),
          ]

          splitter_source = recognizers.map { |r| r.regex.source }.join("|")
          splitter = Regexp.new("(#{splitter_source})")

          Tokenizer.new(
            recognizers + [
              TokenRecognizer.new(:plaintext, //)  # catch-all
            ], splitter
          )
        end
      end

    end
  end
end
