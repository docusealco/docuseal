# frozen_string_literal: true

module Regexp::Syntax
  module Token
    module Meta
      Basic       = %i[dot].freeze
      Alternation = %i[alternation].freeze
      Extended    = Basic + Alternation

      All = Extended
      Type = :meta
    end

    Map[Meta::Type] = Meta::All

    # alias for symmetry between Token::* and Expression::*
    module Alternation
      All  = Meta::Alternation
      Type = Meta::Type
    end
  end
end
