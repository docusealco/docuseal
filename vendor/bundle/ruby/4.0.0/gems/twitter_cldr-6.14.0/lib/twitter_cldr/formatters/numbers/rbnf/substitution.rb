# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    module Rbnf

      Substitution = Struct.new(:type, :contents, :length) do
        def description
          @description ||= contents.map(&:value).join
        end

        def rule_set_reference
          if item = contents.first
            item.value.gsub("%", "") if item.type == :rule
          end
        end

        def decimal_format
          if item = contents.first
            item.value if item.type == :decimal
          end
        end
      end

    end
  end
end
