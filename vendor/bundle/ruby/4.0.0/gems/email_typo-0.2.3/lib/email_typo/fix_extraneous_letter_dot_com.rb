# frozen_string_literal: true

module EmailTypo
  FixExtraneousLetterDotCom = lambda do |email|
    email
      .gsub(/\..com$/, ".com")
  end
end
