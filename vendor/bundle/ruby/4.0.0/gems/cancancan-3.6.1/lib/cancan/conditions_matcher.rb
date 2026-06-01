# frozen_string_literal: true

module CanCan
  module ConditionsMatcher
    # Matches the block or conditions hash
    def matches_conditions?(action, subject, attribute = nil, *extra_args)
      return call_block_with_all(action, subject, extra_args) if @match_all
      return matches_block_conditions(subject, attribute, *extra_args) if @block
      return matches_non_block_conditions(subject) unless conditions_empty?

      true
    end

    private

    def subject_class?(subject)
      klass = (subject.is_a?(Hash) ? subject.values.first : subject).class
      [Class, Module].include? klass
    end

    def matches_block_conditions(subject, attribute, *extra_args)
      return @base_behavior if subject_class?(subject)

      if attribute
        @block.call(subject, attribute, *extra_args)
      else
        @block.call(subject, *extra_args)
      end
    end

    def matches_non_block_conditions(subject)
      return nested_subject_matches_conditions?(subject) if subject.class == Hash
      return matches_conditions_hash?(subject) unless subject_class?(subject)

      # Don't stop at "cannot" definitions when there are conditions.
      @base_behavior
    end

    def nested_subject_matches_conditions?(subject_hash)
      parent, child = subject_hash.first

      adapter = model_adapter(parent)

      parent_condition_name = adapter.parent_condition_name(parent, child)

      matches_base_parent_conditions = matches_conditions_hash?(parent,
                                                                @conditions[parent_condition_name] || {})

      matches_base_parent_conditions &&
        (!adapter.override_nested_subject_conditions_matching?(parent, child, @conditions) ||
          adapter.nested_subject_matches_conditions?(parent, child, @conditions))
    end

    # Checks if the given subject matches the given conditions hash.
    # This behavior can be overridden by a model adapter by defining two class methods:
    # override_matching_for_conditions?(subject, conditions) and
    # matches_conditions_hash?(subject, conditions)
    def matches_conditions_hash?(subject, conditions = @conditions)
      return true if conditions.is_a?(Hash) && conditions.empty?

      adapter = model_adapter(subject)

      if adapter.override_conditions_hash_matching?(subject, conditions)
        return adapter.matches_conditions_hash?(subject, conditions)
      end

      matches_all_conditions?(adapter, subject, conditions)
    end

    def matches_all_conditions?(adapter, subject, conditions)
      if conditions.is_a?(Hash)
        matches_hash_conditions?(adapter, subject, conditions)
      elsif conditions.respond_to?(:include?)
        conditions.include?(subject)
      else
        subject == conditions
      end
    end

    def matches_hash_conditions?(adapter, subject, conditions)
      conditions.all? do |name, value|
        if adapter.override_condition_matching?(subject, name, value)
          adapter.matches_condition?(subject, name, value)
        else
          condition_match?(subject.send(name), value)
        end
      end
    end

    def condition_match?(attribute, value)
      case value
      when Hash
        hash_condition_match?(attribute, value)
      when Range
        value.cover?(attribute)
      when Enumerable
        value.include?(attribute)
      else
        attribute == value
      end
    end

    def hash_condition_match?(attribute, value)
      if attribute.is_a?(Array) || (defined?(ActiveRecord) && attribute.is_a?(ActiveRecord::Relation))
        array_like_matches_condition_hash?(attribute, value)
      else
        attribute && matches_conditions_hash?(attribute, value)
      end
    end

    def array_like_matches_condition_hash?(attribute, value)
      if attribute.any?
        attribute.any? { |element| matches_conditions_hash?(element, value) }
      else
        # you can use `nil`s in your ability definition to tell cancancan to find
        # objects that *don't* have any children in a has_many relationship.
        #
        # for example, given ability:
        # => can :read, Article, comments: { id: nil }
        # cancancan will return articles where `article.comments == []`
        #
        # this is implemented here. `attribute` is `article.comments`, and it's an empty array.
        # the expression below returns true if this was expected.
        !value.values.empty? && value.values.all?(&:nil?)
      end
    end

    def call_block_with_all(action, subject, *extra_args)
      if subject.class == Class
        @block.call(action, subject, nil, *extra_args)
      else
        @block.call(action, subject.class, subject, *extra_args)
      end
    end

    def model_adapter(subject)
      CanCan::ModelAdapters::AbstractAdapter.adapter_class(subject_class?(subject) ? subject : subject.class)
    end

    def conditions_empty?
      # @conditions might be an ActiveRecord::Associations::CollectionProxy
      # which it's `==` implementation will fetch all records for comparison

      (@conditions.is_a?(Hash) && @conditions == {}) || @conditions.nil?
    end
  end
end
