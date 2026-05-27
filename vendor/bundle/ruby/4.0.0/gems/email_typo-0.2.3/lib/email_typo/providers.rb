# frozen_string_literal: true

module EmailTypo
  Providers = lambda do |email|
    email
      .gsub(/@co?(m|n)a?cas?t{0,2}\./, "@comcast.")
      .gsub(/@sbc?gl?ob[al]{0,2}l?\./, "@sbcglobal.")
      .gsub(/@ver?i?z?on\./, "@verizon.")
      .gsub(/@icl{0,2}oud\./, "@icloud.")
      .gsub(/@outl?ook?\./, "@outlook.")
  end
end
