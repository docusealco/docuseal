# frozen_string_literal: false

module CanCan
  module ModelAdapters
    class Strategies
      class JoinedAliasEachRuleAsExistsSubquery < Base
        def execute!
          model_class
            .joins(
              "JOIN #{quoted_table_name} AS #{quoted_aliased_table_name} ON " \
              "#{quoted_aliased_table_name}.#{quoted_primary_key} = #{quoted_table_name}.#{quoted_primary_key}"
            )
            .where(double_exists_sql)
        end

        def double_exists_sql
          double_exists_sql = ''

          compressed_rules.each_with_index do |rule, index|
            double_exists_sql << ' OR ' if index.positive?
            double_exists_sql << "EXISTS (#{sub_query_for_rule(rule).to_sql})"
          end

          double_exists_sql
        end

        def sub_query_for_rule(rule)
          conditions_extractor = ConditionsExtractor.new(model_class)
          rule_where_conditions = extract_multiple_conditions(conditions_extractor, [rule])
          joins_hash, left_joins_hash = extract_joins_from_rule(rule)
          sub_query_for_rules_and_join_hashes(rule_where_conditions, joins_hash, left_joins_hash)
        end

        def sub_query_for_rules_and_join_hashes(rule_where_conditions, joins_hash, left_joins_hash)
          model_class
            .select('1')
            .joins(joins_hash)
            .left_joins(left_joins_hash)
            .where(
              "#{quoted_table_name}.#{quoted_primary_key} = " \
              "#{quoted_aliased_table_name}.#{quoted_primary_key}"
            )
            .where(rule_where_conditions)
            .limit(1)
        end

        def extract_joins_from_rule(rule)
          joins = {}
          left_joins = {}

          extra_joins_recursive([], rule.conditions, joins, left_joins)
          [joins, left_joins]
        end

        def extra_joins_recursive(current_path, conditions, joins, left_joins)
          conditions.each do |key, value|
            if value.is_a?(Hash)
              current_path << key
              extra_joins_recursive(current_path, value, joins, left_joins)
              current_path.pop
            else
              extra_joins_recursive_merge_joins(current_path, value, joins, left_joins)
            end
          end
        end

        def extra_joins_recursive_merge_joins(current_path, value, joins, left_joins)
          hash_joins = current_path_to_hash(current_path)

          if value.nil?
            left_joins.deep_merge!(hash_joins)
          else
            joins.deep_merge!(hash_joins)
          end
        end

        # Converts an array like [:child, :grand_child] into a hash like {child: {grand_child: {}}
        def current_path_to_hash(current_path)
          hash_joins = {}
          current_hash_joins = hash_joins

          current_path.each do |path_part|
            new_hash = {}
            current_hash_joins[path_part] = new_hash
            current_hash_joins = new_hash
          end

          hash_joins
        end
      end
    end
  end
end
