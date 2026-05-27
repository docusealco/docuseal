# frozen_string_literal: true

module Regexp::Syntax
  module Token
    module Quantifier
      Greedy = %i[
        zero_or_one
        zero_or_more
        one_or_more
      ].freeze

      Reluctant = %i[
        zero_or_one_reluctant
        zero_or_more_reluctant
        one_or_more_reluctant
      ].freeze

      Possessive = %i[
        zero_or_one_possessive
        zero_or_more_possessive
        one_or_more_possessive
      ].freeze

      Interval             = %i[interval].freeze
      IntervalReluctant    = %i[interval_reluctant].freeze
      IntervalPossessive   = %i[interval_possessive].freeze

      IntervalAll = Interval + IntervalReluctant + IntervalPossessive

      V1_8_6 = Greedy + Reluctant + Interval + IntervalReluctant
      All = Greedy + Reluctant + Possessive + IntervalAll
      Type = :quantifier
    end

    Map[Quantifier::Type] = Quantifier::All
  end
end
