# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

# http://unicode.org/reports/tr35/tr35-general.html#Transforms
# http://unicode.org/cldr/utility/transform.jsp

module TwitterCldr
  module Transforms

    class FilteredRuleSet
      attr_reader :filter_rule, :transform_id

      def initialize(filter_rule, transform_id)
        @filter_rule = filter_rule
        @transform_id = transform_id
      end

      def foward?
        true
      end

      def backward?
        false
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

      def invert
        raise NotInvertibleError,
          "cannot invert this #{self.class.name}"
      end

      def transform(text)
        rule_set.transform(text)
      end

      def rule_set
        @rule_set ||= begin
          rs = Transformer.get(transform_id)

          # replace any existing filters in all conversion rules and build
          # a new rule set
          new_rules = rs.rules.map do |rule|
            next rule unless rule.is_conversion_rule_set?
            ConversionRuleSet.new(filter_rule, nil, rule.rules)
          end

          RuleSet.new(new_rules, transform_id)
        end
      end
    end

  end
end
