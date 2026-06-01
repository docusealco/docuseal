# frozen_string_literal: true

module CanCan
  def self.valid_accessible_by_strategies
    strategies = [:left_join]

    unless does_not_support_subquery_strategy?
      strategies.push(:joined_alias_exists_subquery, :joined_alias_each_rule_as_exists_subquery, :subquery)
    end

    strategies
  end

  # You can disable the rules compressor if it's causing unexpected issues.
  def self.rules_compressor_enabled
    return @rules_compressor_enabled if defined?(@rules_compressor_enabled)

    @rules_compressor_enabled = true
  end

  def self.rules_compressor_enabled=(value)
    @rules_compressor_enabled = value
  end

  def self.with_rules_compressor_enabled(value)
    return yield if value == rules_compressor_enabled

    begin
      rules_compressor_enabled_was = rules_compressor_enabled
      @rules_compressor_enabled = value
      yield
    ensure
      @rules_compressor_enabled = rules_compressor_enabled_was
    end
  end

  # Determines how CanCan should build queries when calling accessible_by,
  # if the query will contain a join. The default strategy is `:subquery`.
  #
  #   # config/initializers/cancan.rb
  #   CanCan.accessible_by_strategy = :subquery
  #
  # Valid strategies are:
  # - :subquery - Creates a nested query with all joins, wrapped by a
  #               WHERE IN query.
  # - :left_join - Calls the joins directly using `left_joins`, and
  #                ensures records are unique using `distinct`. Note that
  #                `distinct` is not reliable in some cases. See
  #                https://github.com/CanCanCommunity/cancancan/pull/605
  def self.accessible_by_strategy
    return @accessible_by_strategy if @accessible_by_strategy

    @accessible_by_strategy = default_accessible_by_strategy
  end

  def self.default_accessible_by_strategy
    if does_not_support_subquery_strategy?
      # see https://github.com/CanCanCommunity/cancancan/pull/655 for where this was added
      # the `subquery` strategy (from https://github.com/CanCanCommunity/cancancan/pull/619
      # only works in Rails 5 and higher
      :left_join
    else
      :subquery
    end
  end

  def self.accessible_by_strategy=(value)
    validate_accessible_by_strategy!(value)

    if value == :subquery && does_not_support_subquery_strategy?
      raise ArgumentError, 'accessible_by_strategy = :subquery requires ActiveRecord 5 or newer'
    end

    @accessible_by_strategy = value
  end

  def self.with_accessible_by_strategy(value)
    return yield if value == accessible_by_strategy

    validate_accessible_by_strategy!(value)

    begin
      strategy_was = accessible_by_strategy
      @accessible_by_strategy = value
      yield
    ensure
      @accessible_by_strategy = strategy_was
    end
  end

  def self.validate_accessible_by_strategy!(value)
    return if valid_accessible_by_strategies.include?(value)

    raise ArgumentError, "accessible_by_strategy must be one of #{valid_accessible_by_strategies.join(', ')}"
  end

  def self.does_not_support_subquery_strategy?
    !defined?(CanCan::ModelAdapters::ActiveRecordAdapter) ||
      CanCan::ModelAdapters::ActiveRecordAdapter.version_lower?('5.0.0')
  end
end
