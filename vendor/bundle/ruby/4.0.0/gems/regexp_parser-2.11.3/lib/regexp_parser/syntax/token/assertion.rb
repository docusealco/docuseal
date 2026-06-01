# frozen_string_literal: true

module Regexp::Syntax
  module Token
    module Assertion
      Lookahead = %i[lookahead nlookahead].freeze
      Lookbehind = %i[lookbehind nlookbehind].freeze

      All = Lookahead + Lookbehind
      Type = :assertion
    end

    Map[Assertion::Type] = Assertion::All
  end
end
