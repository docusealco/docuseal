# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    module Rbnf
      class Rule

        SUBSTITUTION_TYPES = [:equals, :left_arrow, :right_arrow]
        MASTER = "x.0"
        IMPROPER_FRACTION = "x.x"
        PROPER_FRACTION = "0.x"
        NEGATIVE = "-x"

        attr_reader :base_value, :rule_text, :radix, :locale

        def initialize(base_value, rule_text, radix, locale)
          @base_value = base_value
          @rule_text = rule_text
          @radix = radix
          @locale = locale
        end

        def divisor
          @divisor ||= begin
            val = base_value.to_i
            exp = val > 0 ? (Math.log(val) / Math.log(radix || 10)).ceil : 1
            div = exp >= 0 ? (radix || 10) ** exp : 1

            # if result is too big, subtract one from exponent and try again
            if div > val
              (radix || 10) ** (exp - 1)
            else
              div
            end
          end
        end

        def substitution_count
          @substitution_count ||= tokens.inject(0) do |ret, token|
            token.is_a?(Substitution) ? ret + 1 : ret
          end
        end

        def even_multiple_of?(num)
          num % divisor == 0
        end

        def normal?
          !(master? || improper_fraction? || proper_fraction? || negative?)
        end

        def master?
          base_value == MASTER
        end

        def improper_fraction?
          base_value == IMPROPER_FRACTION
        end

        def proper_fraction?
          base_value == PROPER_FRACTION
        end

        def negative?
          base_vaue == NEGATIVE
        end

        def tokens
          @tokens ||= inline_substitutions(
            tokenizer.tokenize(rule_text)
          )
        end

        private

        def inline_substitutions(tokens)
          parser.parse(tokens, locale: locale)
        end

        def parser
          @@parser ||= RuleParser.new
        end

        def tokenizer
          @@tokenizer ||= TwitterCldr::Tokenizers::RbnfTokenizer.new
        end
      end

    end
  end
end
