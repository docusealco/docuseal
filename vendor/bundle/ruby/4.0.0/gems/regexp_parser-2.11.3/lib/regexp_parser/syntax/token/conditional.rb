# frozen_string_literal: true

module Regexp::Syntax
  module Token
    module Conditional
      Delimiters = %i[open close].freeze

      Condition  = %i[condition_open condition condition_close].freeze
      Separator  = %i[separator].freeze

      All = Conditional::Delimiters + Conditional::Condition + Conditional::Separator

      Type = :conditional
    end

    Map[Conditional::Type] = Conditional::All
  end
end
