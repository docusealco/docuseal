# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'bigdecimal'

module TwitterCldr
  module Formatters
    module Rbnf

      RuleSet = Struct.new(:rules, :name, :access) do
        def rule_for_value(base_value)
          if idx = rule_index_for(base_value)
            rules[idx]
          end
        end

        def previous_rule_for(rule)
          if idx = rule_index_for(rule.base_value)
            rules[idx - 1] if idx > 0
          end
        end

        def master_rule
          rule_for_value(Rule::MASTER)
        end

        def improper_fraction_rule
          rule_for_value(Rule::IMPROPER_FRACTION)
        end

        def proper_fraction_rule
          rule_for_value(Rule::PROPER_FRACTION)
        end

        def negative_rule
          rule_for_value(Rule::NEGATIVE)
        end

        def private?
          access == "private"
        end

        def public?
          access == "public"
        end

        def each_numeric_rule
          if block_given?
            search_start_index.upto(rules.size - 1) do |i|
              yield rules[i]
            end
          else
            to_enum(:each_numeric_rule)
          end
        end

        # fractional: i.e. whether or not to consider the rule set a "fractional" rule set (special rules apply)
        def rule_for(number, fractional = false)
          if fractional
            fractional_rule_for(number)
          else
            normal_rule_for(number)
          end
        end

        private

        # Adapted from: http://grepcode.com/file/repo1.maven.org/maven2/com.ibm.icu/icu4j/51.2/com/ibm/icu/text/NFRuleSet.java#NFRuleSet.findFractionRuleSetRule%28double%29
        def fractional_rule_for(number)
          # the obvious way to do this (multiply the value being formatted
          # by each rule's base value until you get an integral result)
          # doesn't work because of rounding error.  This method is more
          # accurate

          # find the least common multiple of the rules' base values
          # and multiply this by the number being formatted.  This is
          # all the precision we need, and we can do all of the rest
          # of the math using integer arithmetic
          index = search_start_index
          index += 1 while rules[index].base_value == 0
          least_common_multiple = rules[index].base_value

          (index + 1).upto(rules.size - 1) do |i|
            least_common_multiple = lcm(least_common_multiple, rules[i].base_value)
          end

          numerator = (number * least_common_multiple).round

          # for each rule, do the following...
          difference = 10 ** 30  # some absurdly large number
          winner = 0

          index.upto(rules.size - 1) do |i|
            # "numerator" is the numerator of the fraction, if the
            # denominator is the LCD.  The numerator, if the rule's
            # base value is the denomiator, is "numerator" times
            # the base value divided by the LCD.  Here we check to
            # see if that's an integer, and if not, how close it is
            # to being an integer.
            temp_difference = numerator * BigDecimal(rules[i].base_value) % least_common_multiple

            # normalize the result of the above calculation: we want
            # the numerator's distance from the CLOSEST multiple
            # of the LCD
            if (least_common_multiple - temp_difference) < temp_difference
              temp_difference = least_common_multiple - temp_difference
            end

            # if this is as close as we've come, keep track of how close
            # that is, and the line number of the rule that did it.  If
            # we've scored a direct hit, we don't have to look at any more
            # rules
            if temp_difference < difference
              difference = temp_difference
              winner = i

              break if difference == 0
            end
          end

          # if we have two successive rules that both have the winning base
          # value, then the first one (the one we found above) is used if
          # the numerator of the fraction is 1 and the second one is used if
          # the numerator of the fraction is anything else (this lets us
          # do things like "one third"/"two thirds" without haveing to define
          # a whole bunch of extra rule sets)
          if (winner + 1) < rules.length && rules[winner + 1].base_value == rules[winner].base_value
            if (number * rules[winner].base_value).round < 1 || (number * rules[winner].base_value).round >= 2
              winner += 1
            end
          end

          # finally, return the winning rule
          rules[winner]
        end

        # Adapted from: http://grepcode.com/file/repo1.maven.org/maven2/com.ibm.icu/icu4j/51.2/com/ibm/icu/text/NFRuleSet.java#NFRuleSet.lcm%28long%2Clong%29
        def lcm(x, y)
          # binary gcd algorithm from Knuth, "The Art of Computer Programming,"
          # vol. 2, 1st ed., pp. 298-299
          x1 = x
          y1 = y
          p2 = 0

          while (x1 & 1) == 0 && (y1 & 1) == 0
            p2 += 1
            x1 >>= 1
            y1 >>= 1
          end

          t = (x1 & 1) == 1 ? -y1 : x1

          while t != 0
            t >>= 1 while (t & 1) == 0
            t > 0 ? x1 = t : y1 = -t
            t = x1 - y1
          end

          gcd = x1 << p2
          x / gcd * y
        end

        # If the rule set is a regular rule set, do the following:
        #
        # If the rule set includes a master rule (and the number was passed in as a double), use the master rule.  (If the number being formatted was passed in as a long, the master rule is ignored.)
        # If the number is negative, use the negative-number rule.
        # If the number has a fractional part and is greater than 1, use the improper fraction rule.
        # If the number has a fractional part and is between 0 and 1, use the proper fraction rule.
        # Binary-search the rule list for the rule with the highest base value less than or equal to the number. If that rule has two substitutions, its base value is not an even multiple of its divisor, and the number is an even multiple of the rule's divisor, use the rule that precedes it in the rule list. Otherwise, use the rule itself.

        def normal_rule_for(number)
          if rule = master_rule
            rule
          elsif number < 0 && rule = negative_rule
            rule
          elsif contains_fraction?(number) && number > 1 && rule = improper_fraction_rule
            rule
          elsif contains_fraction?(number) && number > 0 && number < 1 && rule = proper_fraction_rule
            rule
          else
            if rule = rule_for_value(number.abs)
              use_prev_rule = rule.substitution_count == 2 &&
                !rule.even_multiple_of?(rule.base_value) &&
                rule.even_multiple_of?(number)

              if use_prev_rule
                previous_rule_for(rule)
              else
                rule
              end
            else
              rules[search_start_index] || rules.first
            end
          end
        end

        def contains_fraction?(number)
          number != number.floor
        end

        def rule_index_for(base_value)
          if rule_index = special_rule_index_for(base_value)
            return rule_index
          end

          if is_numeric?(base_value)
            # binary search (base_value must be a number for this to work)
            low = search_start_index
            high = rules.size - 1

            while low <= high
              mid = (low + high) / 2
              mid_base_value = rules[mid].base_value

              case
                when mid_base_value > base_value
                  high = mid - 1
                when mid_base_value < base_value
                  low = mid + 1
                else
                  break
              end
            end

            # Binary-search the rule list for the rule with the highest base value less than or equal to the number.
            if rules[mid].base_value <= base_value
              mid
            else
              mid > 0 ? mid - 1 : mid
            end
          end
        end

        def special_rule_index_for(base_value)
          (0...search_start_index).each do |i|
            if rules[i].base_value == base_value
              return i
            end
          end
          nil
        end

        def search_start_index
          @search_start_index ||= begin
            rules.find_index do |rule|
              is_numeric?(rule.base_value)
            end || 0
          end
        end

        def is_numeric?(val)
          !!(val.to_s =~ /\A[\d]+\.?[\d]{0,}\z/)
        end
      end

    end
  end
end
