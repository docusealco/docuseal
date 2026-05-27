# frozen_string_literal: true

module Regexp::Syntax
  module Token
    module Anchor
      Basic       = %i[bol eol].freeze
      Extended    = Basic + %i[word_boundary nonword_boundary]
      String      = %i[bos eos eos_ob_eol].freeze
      MatchStart  = %i[match_start].freeze

      All = Extended + String + MatchStart
      Type = :anchor
    end

    Map[Anchor::Type] = Anchor::All
  end
end
