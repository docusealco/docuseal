# frozen_string_literal: true

require_relative 'conditions_matcher.rb'
module CanCan
  class RulesCompressor
    attr_reader :initial_rules, :rules_collapsed

    def initialize(rules)
      @initial_rules = rules
      @rules_collapsed = compress(@initial_rules)
    end

    def compress(array)
      array = simplify(array)
      idx = array.rindex(&:catch_all?)
      return array unless idx

      value = array[idx]
      array[idx..-1]
        .drop_while { |n| n.base_behavior == value.base_behavior }
        .tap { |a| a.unshift(value) unless value.cannot_catch_all? }
    end

    # If we have A OR (!A AND anything ), then we can simplify to A OR anything
    # If we have A OR (A OR anything ), then we can simplify to A OR anything
    # If we have !A AND (A OR something), then we can simplify it to !A AND something
    # If we have !A AND (!A AND something), then we can simplify it to !A AND something
    #
    # So as soon as we see a condition that is the same as the previous one,
    # we can skip it, no matter of the base_behavior
    def simplify(rules)
      seen = Set.new
      rules.reverse_each.filter_map do |rule|
        next if seen.include?(rule.conditions)

        seen.add(rule.conditions)
        rule
      end.reverse
    end
  end
end
