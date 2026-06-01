# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Transforms

      # Base class for transforms
      class TransformRule < Rule
        class << self
          def parse(rule_text, symbol_table, index)
            rule_text = Rule.remove_comment(rule_text).strip
            rule_text = rule_text[2..-2].strip if rule_text.start_with?('::')
            tokens = tokenizer.tokenize(rule_text)
            forward_form, backward_form = parser.parse(tokens)

            transform_class = transforms.find do |transform|
              transform.accepts?(forward_form, backward_form)
            end

            transform_class.new(forward_form, backward_form)
          end

          def accepts?(rule_text)
            rule_text = Rule.remove_comment(rule_text)
            rule_text = rule_text[2..-2].strip
            tokens = tokenizer.tokenize(rule_text)
            forward_form, backward_form = parser.parse(tokens)

            transforms.any? do |transform|
              transform.accepts?(forward_form, backward_form)
            end
          rescue Exception
            false
          end

          def null?
            false
          end

          def blank?
            false
          end

          private

          def parser
            @parser ||= Parser.new
          end

          def tokenizer
            @tokenizer ||=
              TwitterCldr::Tokenizers::UnicodeRegexTokenizer.new
          end

          # make this a method rather than a constant to avoid issues
          # with Marshal.load
          def transforms
            @transforms ||= [
              NullTransform, NormalizationTransform, CasingTransform,
              NamedTransform, BreakInternalTransform
            ]
          end
        end

        attr_reader :forward_form, :backward_form

        def initialize(forward_form, backward_form)
          @forward_form = forward_form
          @backward_form = backward_form
          after_initialize
        end

        def is_transform_rule?
          true
        end

        def forward?
          !forward_form.null?
        end

        def backward?
          false
        end

        def invert
          self.class.new(backward_form, forward_form)
        end

        private

        def after_initialize
        end
      end

    end
  end
end
