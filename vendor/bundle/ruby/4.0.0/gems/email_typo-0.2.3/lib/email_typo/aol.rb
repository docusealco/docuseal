# frozen_string_literal: true

module EmailTypo
  Aol = lambda do |email|
    email.gsub(/@(ol|ao|ail)\./, "@aol.")
  end
end
