# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    module Rbnf

      RuleGroup = Struct.new(:rule_sets, :name) do
        def rule_set_for(rule_set_name)
          rule_sets.find do |rule_set|
            rule_set.name == rule_set_name
          end
        end
      end

    end
  end
end