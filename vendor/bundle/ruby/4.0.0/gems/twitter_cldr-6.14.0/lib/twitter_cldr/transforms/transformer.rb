# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms

    class InvalidTransformRuleError < StandardError; end

    class Transformer
      RULE_CLASSES = [
        CommentRule,
        VariableRule,
        Transforms::TransformRule,
        Filters::FilterRule,
        Conversions::ConversionRule,
      ]

      class << self
        def exists?(transform_id_or_str)
          !!get(transform_id_or_str)
        rescue => e
          false
        end

        def get(transform_id_or_str)
          id = parse_id(transform_id_or_str)

          if resource_exists?(id)
            load(id).forward_rule_set
          else
            reversed_id = id.reverse

            if resource_exists?(reversed_id)
              load(reversed_id).backward_rule_set
            end
          end
        end

        def each_transform
          if block_given?
            TransformId.transform_id_map.each do |aliass, _|
              yield aliass
            end
          else
            to_enum(__method__)
          end
        end

        private

        def parse_id(transform_id)
          case transform_id
            when TransformId
              transform_id
            else
              TransformId.parse(transform_id)
          end
        end

        def load(transform_id)
          transformers[transform_id.to_s] ||= begin
            resource = resource_for(transform_id)
            direction = direction_from(resource)
            new(parse_resource(resource), direction, transform_id)
          end
        end

        def build(rule_list, direction)
          rules = parse_rules(rule_list)
          new(rules, direction)
        end

        def direction_from(resource)
          case transform_from(resource)[:direction]
            when 'both'
              :bidirectional
            else
              :forward
          end
        end

        def transformers
          @transformers ||= {}
        end

        def parse_resource(resource)
          parse_rules(rules_from(resource))
        end

        def parse_rules(rule_list)
          symbol_table = {}
          rules = []

          parse_each_rule(rule_list, symbol_table) do |rule|
            if rule.is_variable?
              symbol_table[rule.name] = rule
            elsif !rule.is_comment?
              rules << rule
            end
          end

          rules
        end

        def parse_each_rule(rule_list, symbol_table)
          rule_list.each_with_index do |rule_text, idx|
            if klass = identify_class(rule_text)
              rule = klass.parse(
                rule_text, symbol_table, idx
              )

              yield rule
            else
              raise InvalidTransformRuleError,
                "Invalid rule: '#{rule_text}'"
            end
          end
        end

        def identify_class(rule_text)
          RULE_CLASSES.find do |klass|
            klass.accepts?(rule_text)
          end
        end

        def rules_from(resource)
          transform_from(resource)[:rules]
        end

        def transform_from(resource)
          resource[:transforms].first
        end

        def resource_for(transform_id)
          TwitterCldr.get_resource(
            'shared', 'transforms', transform_id.file_name
          )
        end

        def resource_exists?(transform_id)
          TwitterCldr.resource_exists?(
            'shared', 'transforms', transform_id.file_name
          )
        end
      end

      attr_reader :rules, :direction, :transform_id

      def initialize(rules, direction, transform_id)
        @rules = rules
        @direction = direction
        @transform_id = transform_id
      end

      # all rules are either forward or bidirectional
      def bidirectional?
        direction == :bidirectional
      end

      def forward_rule_set
        @forward_rule_set ||= RuleSet.new(rules, transform_id)
      end

      def backward_rule_set
        if bidirectional?
          @backward_rule_set ||= forward_rule_set.invert
        else
          raise NotInvertibleError,
            "cannot invert this #{self.class.name}"
        end
      end
    end

  end
end
