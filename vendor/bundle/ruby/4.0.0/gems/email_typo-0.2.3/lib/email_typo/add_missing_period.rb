# frozen_string_literal: true

module EmailTypo
  AddMissingPeriod = lambda do |email|
    email.gsub(/([^.])(com|org|net)$/, "\\1.\\2")
  end
end
