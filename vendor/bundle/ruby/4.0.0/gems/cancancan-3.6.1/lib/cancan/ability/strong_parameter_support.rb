# frozen_string_literal: true

module CanCan
  module Ability
    module StrongParameterSupport
      # Returns an array of attributes suitable for use with strong parameters
      #
      # Note: reversing the relevant rules is important. Normal order means that 'cannot'
      # rules will come before 'can' rules. However, you can't remove attributes before
      # they are added. The 'reverse' is so that attributes will be added before the
      # 'cannot' rules remove them.
      def permitted_attributes(action, subject)
        relevant_rules(action, subject)
          .reverse
          .select { |rule| rule.matches_conditions? action, subject }
          .each_with_object(Set.new) do |rule, set|
          attributes = get_attributes(rule, subject)
          # add attributes for 'can', remove them for 'cannot'
          rule.base_behavior ? set.merge(attributes) : set.subtract(attributes)
        end.to_a
      end

      private

      def subject_class?(subject)
        klass = (subject.is_a?(Hash) ? subject.values.first : subject).class
        [Class, Module].include? klass
      end

      def get_attributes(rule, subject)
        klass = subject_class?(subject) ? subject : subject.class
        # empty attributes is an 'all'
        if rule.attributes.empty? && klass < ActiveRecord::Base
          klass.attribute_names.map(&:to_sym) - Array(klass.primary_key)
        else
          rule.attributes
        end
      end
    end
  end
end
