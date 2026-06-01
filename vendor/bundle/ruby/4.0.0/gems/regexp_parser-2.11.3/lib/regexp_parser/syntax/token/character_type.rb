# frozen_string_literal: true

module Regexp::Syntax
  module Token
    module CharacterType
      Basic     = [].freeze
      Extended  = %i[digit nondigit space nonspace word nonword].freeze
      Hex       = %i[hex nonhex].freeze

      Clustered = %i[linebreak xgrapheme].freeze

      All = Basic + Extended + Hex + Clustered
      Type = :type
    end

    Map[CharacterType::Type] = CharacterType::All
  end
end
