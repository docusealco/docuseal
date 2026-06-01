# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    module Rbnf

      class Plural
        def self.from_string(locale, str)
          # $(cardinal,one{ tysiąc}few{ tysiące}other{ tysięcy})$
          plural_type, cases = str.gsub(/\$\((.*)\)\$/, '\1').split(',')

          # one{ tysiąc}few{ tysiące}other{ tysięcy}
          cases = cases.scan(/([\w]+)\{([^}]+)\}/).inject({}) do |ret, case_arr|
            ret[case_arr.first.to_sym] = case_arr.last
            ret
          end

          new(locale, plural_type.to_sym, cases)
        end

        attr_reader :locale, :plural_type, :cases

        # plural_type = cardinal, etc
        # cases = hash of form one: "foo", two: "bar"
        def initialize(locale, plural_type, cases)
          @locale = locale
          @plural_type = plural_type
          @cases = cases
        end

        def render(number)
          rule_name = TwitterCldr::Formatters::Plurals::Rules.rule_for(
            number, locale, plural_type
          )

          cases[rule_name] || cases[:other]
        end

        def type
          :plural
        end
      end

    end
  end
end
