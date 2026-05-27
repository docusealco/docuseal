# frozen_string_literal: true

module EmailTypo
  # require the o, to not false-positive .gr e-mails
  DotOrg = lambda do |email|
    email.gsub(/\.og?r?g{0,2}$/, ".org")
  end
end
