# frozen_string_literal: true

module EmailTypo
  PeriodAroundAtSign = lambda do |email|
    email.gsub(/(\.@|@\.)/, "@")
  end
end
