# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms

    class NotInvertibleError < StandardError; end

    # Base class for all transform rules
    class Rule
      STRING_TYPES = [
        :escaped_char, :unicode_char, :escaped_backslash,
        :quoted_string, :doubled_quote
      ]

      class << self
        def replace_symbols(tokens, symbol_table)
          tokens.inject([]) do |ret, token|
            ret + if token.type == :variable
              symbol_table[token.value].value_tokens
            else
              Array(token)
            end
          end
        end

        def token_value(token)
          case token.type
            when :escaped_char
              token.value.sub(/\A\\/, '')
            when :unicode_char
              hex = token.value.sub(/\A\\u/, '')
              [hex.to_i(16)].pack('U*')
            when :escaped_backslash
              '\\'
            when :quoted_string
              token.value[1..-2]
            when :doubled_quote
              "'"
            else
              token.value
          end
        end

        def token_string(tokens)
          tokens.inject('') do |ret, token|
            ret + token_value(token)
          end
        end

        def regexp_token_string(tokens)
          tokens.inject('') do |ret, token|
            val = token_value(token)

            ret + case token.type
              when *STRING_TYPES
                Regexp.escape(val)
              else
                val
            end
          end
        end

        def remove_comment(rule_text)
          # comment must come after semicolon
          if rule_idx = rule_text.index(/;[\s]*#/)
            rule_text[0..rule_idx]
          else
            rule_text
          end
        end
      end

      def token_value(token)
        self.class.token_value(token)
      end

      def token_string(tokens)
        self.class.token_string(tokens)
      end

      def is_filter_rule?
        false
      end

      def is_transform_rule?
        false
      end

      def is_conversion_rule?
        false
      end

      def is_conversion_rule_set?
        false
      end

      def is_variable?
        false
      end

      def is_comment?
        false
      end

      def forward?
        raise NotImplementedError,
          "#{__method__} must be defined in derived classes"
      end

      def backward?
        raise NotImplementedError,
          "#{__method__} must be defined in derived classes"
      end

      def invert
        raise NotImplementedError,
          "#{__method__} must be defined in derived classes"
      end
    end

  end
end
