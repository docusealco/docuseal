# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Transforms

      class Parser < TwitterCldr::Parsers::Parser
        private

        def do_parse(options)
          forward = forward_form
          backward = backward_form
          [forward, backward]
        end

        def forward_form
          spaces

          unless open_paren?(current_token)
            form
          end
        end

        def backward_form
          if open_paren?(current_token)
            next_token(:special_char)
            spaces

            frm = if close_paren?(current_token)
              BlankTransform.instance
            else
              form
            end

            spaces
            next_token(:special_char)
            frm
          end
        end

        def form
          filter_tokens = filter
          transform_tokens = transform

          TransformPair.new(
            join_tokens(filter_tokens).strip,
            join_tokens(transform_tokens).strip
          )
        end

        def filter
          if current_token.type == :character_set
            [current_token].tap do
              next_token(:character_set)
            end
          else
            consume_until_balanced
          end
        end

        def transform
          consume_while do |token|
            token.value =~ /[\w\s\-]/
          end
        end

        def spaces
          consume_while do |token|
            token.value =~ /[\s]+/
          end
        end

        def join_tokens(tokens)
          tokens.inject('') do |ret, token|
            ret << token.value
          end
        end

        def consume_while
          consumed_tokens = []

          while !eof? && yield(current_token)
            consumed_tokens << current_token
            next_token(current_token.type)
          end

          consumed_tokens
        end

        def consume_until_balanced
          open_brackets = 0
          consumed_tokens = []

          if is_opening?(current_token) || is_closing?(current_token)
            loop do
              open_brackets += 1 if is_opening?(current_token)
              open_brackets -= 1 if is_closing?(current_token)
              consumed_tokens << current_token
              next_token(current_token.type)
              break if open_brackets == 0 || eof?
            end
          end

          consumed_tokens
        end

        def open_paren?(token)
          token && token.type == :special_char && token.value == '('
        end

        def close_paren?(token)
          token && token.type == :special_char && token.value == ')'
        end

        def is_opening?(token)
          token && token.type == :open_bracket || open_paren?(token)
        end

        def is_closing?(token)
          token && token.type == :close_bracket || close_paren?(token)
        end
      end

    end
  end
end
