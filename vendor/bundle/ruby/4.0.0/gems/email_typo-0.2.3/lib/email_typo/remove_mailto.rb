# frozen_string_literal: true

module EmailTypo
  RemoveMailTo = lambda do |email|
    email.gsub(/\Amailto:/, "")
  end
end
