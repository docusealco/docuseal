# frozen_string_literal: true

module Regexp::Syntax
  module Token
    module Group
      Basic     = %i[capture close].freeze
      Extended  = Basic + %i[options options_switch]

      Named     = %i[named].freeze
      Atomic    = %i[atomic].freeze
      Passive   = %i[passive].freeze
      Comment   = %i[comment].freeze

      V1_8_6 = Group::Extended + Group::Named + Group::Atomic +
               Group::Passive + Group::Comment

      V2_4_1 = %i[absence].freeze

      All = V1_8_6 + V2_4_1
      Type = :group
    end

    Map[Group::Type] = Group::All
  end
end
