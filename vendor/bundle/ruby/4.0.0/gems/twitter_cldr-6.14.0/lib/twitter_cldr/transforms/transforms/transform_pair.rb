# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Transforms

      class TransformPair
        attr_reader :filter, :transform

        def initialize(filter, transform)
          @filter = filter
          @transform = transform
        end

        def has_transform?
          transform && !transform.empty?
        end

        def has_filter?
          filter && !filter.empty?
        end

        def apply_to(cursor)
          cursor.set_text(rule_set.transform(cursor.text))
          cursor.reset_position
        end

        def null?
          false
        end

        def blank?
          false
        end

        private

        def rule_set
          @rule_set ||= if has_filter? && has_transform?
            FilteredRuleSet.new(filter_rule, transform)
          elsif has_transform?
            Transformer.get(transform)
          else
            raise NotImplementedError,
              'attempted to create a rule set with only a filter, which '\
              'has undefined behavior'
          end
        end

        def filter_rule
          @filter_rule ||= if has_filter?
            Filters::FilterRule.parse(filter, nil, nil)
          end
        end
      end

    end
  end
end
