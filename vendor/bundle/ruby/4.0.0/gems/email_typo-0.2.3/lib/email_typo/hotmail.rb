# frozen_string_literal: true

module EmailTypo
  Hotmail = lambda do |email|
    email
      .gsub(
        /@h((?!anmail)(i|o|p)?y?t?o?a?r?m?n?t?m?[aikl]{1,3}l?)\./,
        "@hotmail."
      )
      .gsub(/@otmail\.com/, "@hotmail.com")
      .gsub(/@hotmail.com[a-z]+/, "@hotmail.com")
  end
end
