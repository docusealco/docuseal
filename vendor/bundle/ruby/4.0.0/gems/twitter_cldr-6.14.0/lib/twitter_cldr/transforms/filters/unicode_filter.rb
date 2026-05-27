# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Filters

      class UnicodeFilter < FilterRule
        class << self
          def parse(rule_text, symbol_table)
            rule_text = Rule.remove_comment(rule_text).strip
            rule_text = rule_text[2..-2].strip if rule_text.start_with?('::')
            direction = direction_for(rule_text)

            re = TwitterCldr::Shared::UnicodeRegex.compile(
              clean_rule(rule_text, direction)
            )

            # filters are always just a unicode set
            new(re.elements.first.to_set.to_set, direction)
          rescue => e
            binding.irb
          end

          def accepts?(rule_text)
            !!(rule_text =~ /\A::[\s]*\(?[\s]*\[/)
          end

          private

          def direction_for(rule_text)
            if rule_text.start_with?('(')
              :backward
            else
              :forward
            end
          end

          def clean_rule(rule_text, direction)
            if direction == :backward
              rule_text[1..-2].strip
            else
              rule_text
            end
          end
        end

        attr_reader :charset, :direction

        def initialize(charset, direction)
          @charset = charset
          @direction = direction
        end

        def resolve(symbol_table)
          self
        end

        def matches?(cursor)
          charset.include?(cursor.text[cursor.position].ord)
        end

        def forward?
          direction == :forward
        end

        def backward?
          direction == :backward
        end
      end

    end
  end
end
