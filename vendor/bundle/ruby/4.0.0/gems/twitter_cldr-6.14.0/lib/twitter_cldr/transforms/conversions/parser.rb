# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Conversions

      class Parser < TwitterCldr::Parsers::Parser
        private

        def do_parse(options)
          first_side = side
          direction = get_direction_from(current_token)
          next_token(:direction)
          second_side = side

          first_side, second_side = rearrange_sides(
            direction, first_side, second_side
          )

          ConversionRule.new(
            direction, first_side, second_side,
            options[:original_rule_text],
            options[:index]
          )
        end

        def rearrange_sides(direction, first_side, second_side)
          case direction
            when :backward
              [second_side, first_side]
            else
              [first_side, second_side]
          end
        end

        # a { b | c } d <> e { f | g } h ;
        def side
          prev_cluster = next_token_cluster
          before_context = nil
          after_context = nil
          key = nil
          cursor_offset = 0

          until current_token.type == :direction || current_token.type == :semicolon
            case current_token.type
              when :before_context
                before_context = prev_cluster
                next_token(:before_context)
                prev_cluster = next_token_cluster
              when :cursor
                next_token(:cursor)
                cur_cluster = next_token_cluster
                key = prev_cluster + cur_cluster
                prev_cluster = cur_cluster
                cursor_offset = -cur_cluster.size
              when :after_context
                next_token(:after_context)
                after_context = next_token_cluster
            end
          end

          key ||= prev_cluster

          Side.new(
            join_values(before_context),
            key,
            join_values(after_context),
            cursor_offset
          )
        end

        def join_values(tokens)
          Array(tokens).map(&:value).join
        end

        def next_token_cluster
          tokens = []

          until is_operator?(current_token) || current_token.type == :semicolon
            tokens << current_token
            next_token(current_token.type)
          end

          tokens
        end

        def is_operator?(token)
          case token.type
            when :direction, :after_context, :before_context, :cursor
              true
            else
              false
          end
        end

        def get_direction_from(token)
          case token.value
            when '>'
              :forward
            when '<'
              :backward
            when '<>'
              :bidirectional
          end
        end
      end

    end
  end
end
