# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    module Rbnf

      [:InvalidRbnfTokenError, :RuleFormatter, :NormalRuleFormatter,
      :NegativeRuleFormatter, :MasterRuleFormatter, :ProperFractionRuleFormatter,
      :ImproperFractionRuleFormatter].each do |formatter|
        autoload formatter, "twitter_cldr/formatters/numbers/rbnf/formatters"
      end

      autoload :Rule,         "twitter_cldr/formatters/numbers/rbnf/rule"
      autoload :RuleSet,      "twitter_cldr/formatters/numbers/rbnf/rule_set"
      autoload :RuleGroup,    "twitter_cldr/formatters/numbers/rbnf/rule_group"
      autoload :RuleParser,   "twitter_cldr/formatters/numbers/rbnf/rule_parser"
      autoload :Substitution, "twitter_cldr/formatters/numbers/rbnf/substitution"
      autoload :Plural,       "twitter_cldr/formatters/numbers/rbnf/plural"

      class PrivateRuleSetError < StandardError; end

      class RbnfFormatter

        DEFAULT_SPELLOUT_OPTIONS = {
          rule_group: "SpelloutRules",
          rule_set: "spellout-numbering"
        }

        def self.supported_locale?(locale)
          TwitterCldr.resource_exists?('locales', locale, 'rbnf')
        end

        attr_reader :locale

        def initialize(locale = TwitterCldr.locale)
          @locale = TwitterCldr.convert_locale(locale)
        end

        def format(number, options = {})
          rule_group_name, rule_set_name = *if options[:rule_group].nil? && options[:rule_set].nil?
            [DEFAULT_SPELLOUT_OPTIONS[:rule_group], DEFAULT_SPELLOUT_OPTIONS[:rule_set]]
          else
            [options[:rule_group], options[:rule_set]]
          end

          if rule_group = rule_group_by_name(rule_group_name)
            if rule_set = rule_group.rule_set_for(rule_set_name)
              if rule_set.public?
                RuleFormatter.format(number, rule_set, rule_group, locale)
              else
                raise PrivateRuleSetError.new(
                  "#{rule_set_name} is a private rule set and cannot be used directly."
                )
              end
            end
          end
        end

        def group_names
          @group_names ||= resource.map { |g| g[:type] }
        end

        def rule_set_names_for_group(group_name)
          cache_key = TwitterCldr::Utils.compute_cache_key(locale, group_name)

          rule_set_name_cache[cache_key] ||= begin
            if rule_group = rule_group_by_name(group_name)
              rule_group.rule_sets.inject([]) do |ret, rule_set|
                ret << rule_set.name if rule_set.public?
                ret
              end
            end
          end

          rule_set_name_cache[cache_key] || []
        end

        private

        def rule_group_by_name(name)
          cache_key = TwitterCldr::Utils.compute_cache_key(locale, name)

          rule_group_cache[cache_key] ||= begin
            group_data = resource.find do |group|
              group[:type] == name
            end

            if group_data
              rule_group_from_resource(group_data)
            end
          end
        end

        def rule_group_cache
          @@rule_group_cache ||= {}
        end

        def rule_set_name_cache
          @@rule_set_name_cache ||= {}
        end

        def rule_set_from_resource(rule_set_data)
          RuleSet.new(
            rule_set_data[:rules].map do |rule|
              Rule.new(rule[:value], rule[:rule], rule[:radix], locale)
            end,
            rule_set_data[:type],
            rule_set_data[:access] || "public"
          )
        end

        def rule_group_from_resource(group_data)
          RuleGroup.new(
            group_data[:ruleset].map do |rule_set_data|
              rule_set_from_resource(rule_set_data)
            end,
            group_data[:type]
          )
        end

        def resource
          @resource ||= TwitterCldr.get_locale_resource(locale, "rbnf")[locale][:rbnf][:grouping]
        end

      end
    end
  end
end
