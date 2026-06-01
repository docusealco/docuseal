# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
module CanCan
  module ModelAdapters
    class ActiveRecordAdapter < AbstractAdapter
      def self.version_greater_or_equal?(version)
        Gem::Version.new(ActiveRecord.version).release >= Gem::Version.new(version)
      end

      def self.version_lower?(version)
        Gem::Version.new(ActiveRecord.version).release < Gem::Version.new(version)
      end

      attr_reader :compressed_rules

      def initialize(model_class, rules)
        super
        @compressed_rules = if CanCan.rules_compressor_enabled
                              RulesCompressor.new(@rules.reverse).rules_collapsed.reverse
                            else
                              @rules
                            end
        StiNormalizer.normalize(@compressed_rules)
        ConditionsNormalizer.normalize(model_class, @compressed_rules)
      end

      class << self
        # When belongs_to parent_id is a condition for a model,
        # we want to check the parent when testing ability for a hash {parent => model}
        def override_nested_subject_conditions_matching?(parent, child, all_conditions)
          parent_child_conditions(parent, child, all_conditions).present?
        end

        # parent_id condition can be an array of integer or one integer, we check the parent against this
        def nested_subject_matches_conditions?(parent, child, all_conditions)
          id_condition = parent_child_conditions(parent, child, all_conditions)
          return id_condition.include?(parent.id) if id_condition.is_a? Array
          return id_condition == parent.id if id_condition.is_a? Integer

          false
        end

        def parent_child_conditions(parent, child, all_conditions)
          child_class = child.is_a?(Class) ? child : child.class
          parent_class = parent.is_a?(Class) ? parent : parent.class

          foreign_key = child_class.reflect_on_all_associations(:belongs_to).find do |association|
            # Do not match on polymorphic associations or it will throw an error (klass cannot be determined)
            !association.polymorphic? && association.klass == parent.class
          end&.foreign_key&.to_sym

          # Search again in case of polymorphic associations, this time matching on the :has_many side
          # via the :as option, as well as klass
          foreign_key ||= parent_class.reflect_on_all_associations(:has_many).find do |has_many_assoc|
            matching_parent_child_polymorphic_association(has_many_assoc, child_class)
          end&.foreign_key&.to_sym

          foreign_key.nil? ? nil : all_conditions[foreign_key]
        end

        def matching_parent_child_polymorphic_association(parent_assoc, child_class)
          return nil unless parent_assoc.klass == child_class
          return nil if parent_assoc&.options[:as].nil?

          child_class.reflect_on_all_associations(:belongs_to).find do |child_assoc|
            # Only match this way for polymorphic associations
            child_assoc.polymorphic? && child_assoc.name == parent_assoc.options[:as]
          end
        end

        def child_association_to_parent(parent, child)
          child_class = child.is_a?(Class) ? child : child.class
          parent_class = parent.is_a?(Class) ? parent : parent.class

          association = child_class.reflect_on_all_associations(:belongs_to).find do |belongs_to_assoc|
            # Do not match on polymorphic associations or it will throw an error (klass cannot be determined)
            !belongs_to_assoc.polymorphic? && belongs_to_assoc.klass == parent.class
          end

          return association if association

          parent_class.reflect_on_all_associations(:has_many).each do |has_many_assoc|
            association ||= matching_parent_child_polymorphic_association(has_many_assoc, child_class)
          end

          association
        end

        def parent_condition_name(parent, child)
          child_association_to_parent(parent, child)&.name || parent.class.name.downcase.to_sym
        end
      end

      # Returns conditions intended to be used inside a database query. Normally you will not call this
      # method directly, but instead go through ModelAdditions#accessible_by.
      #
      # If there is only one "can" definition, a hash of conditions will be returned matching the one defined.
      #
      #   can :manage, User, :id => 1
      #   query(:manage, User).conditions # => { :id => 1 }
      #
      # If there are multiple "can" definitions, a SQL string will be returned to handle complex cases.
      #
      #   can :manage, User, :id => 1
      #   can :manage, User, :manager_id => 1
      #   cannot :manage, User, :self_managed => true
      #   query(:manage, User).conditions # => "not (self_managed = 't') AND ((manager_id = 1) OR (id = 1))"
      #
      def conditions
        conditions_extractor = ConditionsExtractor.new(@model_class)
        if @compressed_rules.size == 1 && @compressed_rules.first.base_behavior
          # Return the conditions directly if there's just one definition
          conditions_extractor.tableize_conditions(@compressed_rules.first.conditions).dup
        else
          extract_multiple_conditions(conditions_extractor, @compressed_rules)
        end
      end

      def extract_multiple_conditions(conditions_extractor, rules)
        rules.reverse.inject(false_sql) do |sql, rule|
          merge_conditions(sql, conditions_extractor.tableize_conditions(rule.conditions).dup, rule.base_behavior)
        end
      end

      def database_records
        if override_scope
          @model_class.where(nil).merge(override_scope)
        elsif @model_class.respond_to?(:where) && @model_class.respond_to?(:joins)
          build_relation(conditions)
        else
          @model_class.all(conditions: conditions, joins: joins)
        end
      end

      def build_relation(*where_conditions)
        relation = @model_class.where(*where_conditions)
        return relation unless joins.present?

        # subclasses must implement `build_joins_relation`
        build_joins_relation(relation, *where_conditions)
      end

      # Returns the associations used in conditions for the :joins option of a search.
      # See ModelAdditions#accessible_by
      def joins
        joins_hash = {}
        @compressed_rules.reverse_each do |rule|
          deep_merge(joins_hash, rule.associations_hash)
        end
        deep_clean(joins_hash) unless joins_hash.empty?
      end

      private

      # Removes empty hashes and moves everything into arrays.
      def deep_clean(joins_hash)
        joins_hash.map { |name, nested| nested.empty? ? name : { name => deep_clean(nested) } }
      end

      # Takes two hashes and does a deep merge.
      def deep_merge(base_hash, added_hash)
        added_hash.each do |key, value|
          if base_hash[key].is_a?(Hash)
            deep_merge(base_hash[key], value) unless value.empty?
          else
            base_hash[key] = value
          end
        end
      end

      def override_scope
        conditions = @compressed_rules.map(&:conditions).compact
        return unless conditions.any? { |c| c.is_a?(ActiveRecord::Relation) }
        return conditions.first if conditions.size == 1

        raise_override_scope_error
      end

      def raise_override_scope_error
        rule_found = @compressed_rules.detect { |rule| rule.conditions.is_a?(ActiveRecord::Relation) }
        raise Error,
              'Unable to merge an Active Record scope with other conditions. ' \
              "Instead use a hash or SQL for #{rule_found.actions.first} #{rule_found.subjects.first} ability."
      end

      def merge_conditions(sql, conditions_hash, behavior)
        if conditions_hash.blank?
          behavior ? true_sql : false_sql
        else
          merge_non_empty_conditions(behavior, conditions_hash, sql)
        end
      end

      def merge_non_empty_conditions(behavior, conditions_hash, sql)
        conditions = sanitize_sql(conditions_hash)
        case sql
        when true_sql
          behavior ? true_sql : "not (#{conditions})"
        when false_sql
          behavior ? conditions : false_sql
        else
          behavior ? "(#{conditions}) OR (#{sql})" : "not (#{conditions}) AND (#{sql})"
        end
      end

      def false_sql
        sanitize_sql(['?=?', true, false])
      end

      def true_sql
        sanitize_sql(['?=?', true, true])
      end

      def sanitize_sql(conditions)
        @model_class.send(:sanitize_sql, conditions)
      end
    end
  end
end
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/AbcSize

ActiveSupport.on_load(:active_record) do
  send :include, CanCan::ModelAdditions
end
