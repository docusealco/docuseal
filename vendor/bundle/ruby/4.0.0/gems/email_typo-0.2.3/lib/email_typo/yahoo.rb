# frozen_string_literal: true

module EmailTypo
  Yahoo = lambda do |email|
    email.gsub(/@(ya|yh|ua|ah)+h*a*o+\./, "@yahoo.")
  end
end
