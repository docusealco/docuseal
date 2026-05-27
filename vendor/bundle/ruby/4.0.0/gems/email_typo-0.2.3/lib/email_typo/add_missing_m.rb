# frozen_string_literal: true

module EmailTypo
  AddMissingM = lambda do |email|
    email.gsub(/(aol|googlemail|gmail|hotmail|yahoo).co$/, "\\1.com")
  end
end
