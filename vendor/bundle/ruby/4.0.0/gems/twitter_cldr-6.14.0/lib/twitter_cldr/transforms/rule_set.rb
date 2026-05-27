# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

# http://unicode.org/reports/tr35/tr35-general.html#Transforms
# http://unicode.org/cldr/utility/transform.jsp

module TwitterCldr
  module Transforms

    class RuleSet
      attr_reader :rules, :transform_id

      def initialize(rules, transform_id)
        @rules = partition(rules)
        @transform_id = transform_id
      end

      def transform(text)
        cursor = Cursor.new(text.dup)
        rules.each { |rule| rule.apply_to(cursor) }
        cursor.text
      end

      def invert
        self.class.new(
          rules.reverse.map(&:invert), transform_id
        )
      end

      private

      def partition(rules)
        [].tap do |result|
          until rules.empty?
            filter_rule = nil
            inverse_filter_rule = nil

            if is_forward_filter?(rules[0])
              filter_rule = rules[0]
              rules.shift
            end

            trans_rules = take_transforms(rules)
            conv_rules = take_conversions(rules)
            result.concat(trans_rules)

            if !rules.empty? && is_backward_filter?(rules[0])
              inverse_filter_rule = rules[0]
              rules.shift
            end

            unless conv_rules.empty?
              result << make_conversion_rule_set(
                conv_rules, filter_rule, inverse_filter_rule
              )
            end

            # Handles the ConversionRuleSet case, which is neither
            # a transform rule nor a conversion rule.
            # ConversionRuleSets can occasionally exist in the list
            # of rules if, say, the rule set is being inverted and
            # therefore already contains a list of partitioned rules.
            if trans_rules.empty? && conv_rules.empty?
              result << rules.delete_at(0)
            end
          end
        end
      end

      def take_transforms(rules)
        take_rules(rules, &:is_transform_rule?)
      end

      def take_conversions(rules)
        take_rules(rules, &:is_conversion_rule?)
      end

      def take_rules(rules)
        [].tap do |result|
          rules.reject! do |rule|
            if yield(rule)
              result << rule
            else
              break
            end
          end
        end
      end

      def make_conversion_rule_set(rules, filter_rule, inverse_filter_rule)
        TwitterCldr::Transforms::ConversionRuleSet.new(
          filter_rule || Filters::NullFilter.new,
          inverse_filter_rule || Filters::NullFilter.new,
          rules
        )
      end

      def is_forward_filter?(rule)
        rule.is_filter_rule? && !rule.backward?
      end

      def is_backward_filter?(rule)
        rule.is_filter_rule? && rule.backward?
      end
    end

  end
end
