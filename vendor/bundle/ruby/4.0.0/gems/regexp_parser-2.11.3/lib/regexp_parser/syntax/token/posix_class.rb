# frozen_string_literal: true

module Regexp::Syntax
  module Token
    module PosixClass
      Standard = %i[alnum alpha blank cntrl digit graph
                    lower print punct space upper xdigit].freeze

      Extensions = %i[ascii word].freeze

      All = Standard + Extensions
      Type = :posixclass
      NonType = :nonposixclass
    end

    Map[PosixClass::Type]    = PosixClass::All
    Map[PosixClass::NonType] = PosixClass::All
  end
end
