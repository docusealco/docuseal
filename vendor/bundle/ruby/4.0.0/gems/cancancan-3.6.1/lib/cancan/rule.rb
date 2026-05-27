# frozen_string_literal: true

require_relative 'conditions_matcher.rb'
require_relative 'class_matcher.rb'
require_relative 'relevant.rb'

module CanCan
  # This class is used internally and should only be called through Ability.
  # it holds the information about a "can" call made on Ability and provides
  # helpful methods to determine permission checking and conditions hash generation.
  class Rule # :nodoc:
    include ConditionsMatcher
    include Relevant
    include ParameterValidators
    attr_reader :base_behavior, :subjects, :actions, :conditions, :attributes, :block
    attr_writer :expanded_actions, :conditions

    # The first argument when initializing is the base_behavior which is a true/false
    # value. True for "can" and false for "cannot". The next two arguments are the action
    # and subject respectively (such as :read, @project). The third argument is a hash
    # of conditions and the last one is the block passed to the "can" call.
    def initialize(base_behavior, action, subject, *extra_args, &block)
      # for backwards compatibility, attributes are an optional parameter. Check if
      # attributes were passed or are actually conditions
      attributes, extra_args = parse_attributes_from_extra_args(extra_args)
      condition_and_block_check(extra_args, block, action, subject)
      @match_all = action.nil? && subject.nil?
      raise Error, "Subject is required for #{action}" if action && subject.nil?

      @base_behavior = base_behavior
      @actions = wrap(action)
      @subjects = wrap(subject)
      @attributes = wrap(attributes)
      @conditions = extra_args || {}
      @block = block
    end

    def inspect
      repr = "#<#{self.class.name}"
      repr += "#{@base_behavior ? 'can' : 'cannot'} #{@actions.inspect}, #{@subjects.inspect}, #{@attributes.inspect}"

      if with_scope?
        repr += ", #{@conditions.where_values_hash}"
      elsif [Hash, String].include?(@conditions.class)
        repr += ", #{@conditions.inspect}"
      end

      repr + '>'
    end

    def can_rule?
      base_behavior
    end

    def cannot_catch_all?
      !can_rule? && catch_all?
    end

    def catch_all?
      (with_scope? && @conditions.where_values_hash.empty?) ||
        (!with_scope? && [nil, false, [], {}, '', ' '].include?(@conditions))
    end

    def only_block?
      conditions_empty? && @block
    end

    def only_raw_sql?
      @block.nil? && !conditions_empty? && !@conditions.is_a?(Hash)
    end

    def with_scope?
      defined?(ActiveRecord) && @conditions.is_a?(ActiveRecord::Relation)
    end

    def associations_hash(conditions = @conditions)
      hash = {}
      if conditions.is_a? Hash
        conditions.map do |name, value|
          hash[name] = associations_hash(value) if value.is_a? Hash
        end
      end
      hash
    end

    def attributes_from_conditions
      attributes = {}
      if @conditions.is_a? Hash
        @conditions.each do |key, value|
          attributes[key] = value unless [Array, Range, Hash].include? value.class
        end
      end
      attributes
    end

    def matches_attributes?(attribute)
      return true if @attributes.empty?
      return @base_behavior if attribute.nil?

      @attributes.include?(attribute.to_sym)
    end

    private

    def matches_action?(action)
      @expanded_actions.include?(:manage) || @expanded_actions.include?(action)
    end

    def matches_subject?(subject)
      @subjects.include?(:all) || @subjects.include?(subject) || matches_subject_class?(subject)
    end

    def matches_subject_class?(subject)
      SubjectClassMatcher.matches_subject_class?(@subjects, subject)
    end

    def parse_attributes_from_extra_args(args)
      attributes = args.shift if valid_attribute_param?(args.first)
      extra_args = args.shift
      [attributes, extra_args]
    end

    def condition_and_block_check(conditions, block, action, subject)
      return unless conditions.is_a?(Hash) && block

      raise BlockAndConditionsError, 'A hash of conditions is mutually exclusive with a block. ' \
        "Check \":#{action} #{subject}\" ability."
    end

    def wrap(object)
      if object.nil?
        []
      elsif object.respond_to?(:to_ary)
        object.to_ary || [object]
      else
        [object]
      end
    end
  end
end
