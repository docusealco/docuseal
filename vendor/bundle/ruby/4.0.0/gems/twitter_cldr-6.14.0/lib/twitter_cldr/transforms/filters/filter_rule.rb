# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Filters

      # Decides which filter to apply
      class FilterRule < Rule
        class << self
          def parse(rule_text, symbol_table, index)
            Filters::UnicodeFilter.parse(rule_text, symbol_table)
          end

          def accepts?(rule_text)
            Filters::UnicodeFilter.accepts?(rule_text)
          end
        end

        def is_filter_rule?
          true
        end
      end

    end
  end
end
