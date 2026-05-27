# frozen_string_literal: true

module EmailTypo
  Icloud = lambda do |email|
    email.gsub(/@icl{0,2}(?:uo|u|o)?d\./, "@icloud.")
  end
end
