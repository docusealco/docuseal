# frozen_string_literal: true

module EmailTypo
  FixExtraneousNumbers = lambda do |email|
    email.gsub(/\.?\d+$/, "")
  end
end
