# frozen_string_literal: true

module CanCan
  module ModelAdapters
    class AbstractAdapter
      attr_reader :model_class

      def self.inherited(subclass)
        @subclasses ||= []
        @subclasses.insert(0, subclass)
      end

      def self.adapter_class(model_class)
        @subclasses.detect { |subclass| subclass.for_class?(model_class) } || DefaultAdapter
      end

      # Used to determine if the given adapter should be used for the passed in class.
      def self.for_class?(_member_class)
        false # override in subclass
      end

      # Override if you need custom find behavior
      def self.find(model_class, id)
        model_class.find(id)
      end

      # Used to determine if this model adapter will override the matching behavior for a hash of conditions.
      # If this returns true then matches_conditions_hash? will be called. See Rule#matches_conditions_hash
      def self.override_conditions_hash_matching?(_subject, _conditions)
        false
      end

      # Override if override_conditions_hash_matching? returns true
      def self.matches_conditions_hash?(_subject, _conditions)
        raise NotImplemented, 'This model adapter does not support matching on a conditions hash.'
      end

      # Override if parent condition could be under a different key in conditions
      def self.parent_condition_name(parent, _child)
        parent.class.name.downcase.to_sym
      end

      # Used above override_conditions_hash_matching to determine if this model adapter will override the
      # matching behavior for nested subject.
      # If this returns true then nested_subject_matches_conditions? will be called.
      def self.override_nested_subject_conditions_matching?(_parent, _child, _all_conditions)
        false
      end

      # Override if override_nested_subject_conditions_matching? returns true
      def self.nested_subject_matches_conditions?(_parent, _child, _all_conditions)
        raise NotImplemented, 'This model adapter does not support matching on a nested subject.'
      end

      # Used to determine if this model adapter will override the matching behavior for a specific condition.
      # If this returns true then matches_condition? will be called. See Rule#matches_conditions_hash
      def self.override_condition_matching?(_subject, _name, _value)
        false
      end

      # Override if override_condition_matching? returns true
      def self.matches_condition?(_subject, _name, _value)
        raise NotImplemented, 'This model adapter does not support matching on a specific condition.'
      end

      def initialize(model_class, rules)
        @model_class = model_class
        @rules = rules
      end

      def database_records
        # This should be overridden in a subclass to return records which match @rules
        raise NotImplemented, 'This model adapter does not support fetching records from the database.'
      end
    end
  end
end
