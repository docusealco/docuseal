# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms

    class VariableRule < Rule
      class Parser < TwitterCldr::Parsers::Parser
        private

        def do_parse(options)
          var_name = name
          next_token(:equals)
          var_value = value
          [var_name, var_value]
        end

        def name
          current_token.value.tap do
            next_token(:variable)
          end
        end

        def value
          [].tap do |value_parts|
            until current_token.type == :semicolon
              value_parts << current_token
              next_token(current_token.type)
            end
          end
        end
      end

      class << self
        def parse(rule_text, symbol_table, index)
          cleaned_rule_text = Rule.remove_comment(rule_text)
          tokens = tokenizer.tokenize(cleaned_rule_text)
          var_name, value_tokens = parser.parse(tokens)

          VariableRule.new(
            var_name, replace_symbols(
              value_tokens, symbol_table
            )
          )
        end

        def accepts?(rule_text)
          !!(rule_text =~ /\A[\s]*\$[\w]+[\s]*=/)
        end

        private

        def parser
          @parser ||= Parser.new
        end

        def tokenizer
          @tokenizer ||= TwitterCldr::Transforms::Tokenizer.new
        end
      end

      attr_reader :name, :value_tokens

      def initialize(name, value)
        @name = name
        @value_tokens = value
      end

      def is_variable?
        true
      end
    end

  end
end
