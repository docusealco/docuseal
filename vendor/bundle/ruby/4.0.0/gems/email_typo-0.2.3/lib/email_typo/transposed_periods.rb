# frozen_string_literal: true

module EmailTypo
  # can't do "o.gr" => ".org", as ".gr" is a valid TLD
  TransposedPeriods = lambda do |email|
    email
      .gsub(/c\.om$/, ".com")
      .gsub(/n\.et$/, ".net")
  end
end
