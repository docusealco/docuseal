# frozen_string_literal: true

module EmailTypo
  KnownDotCom = lambda do |email|
    email
      .gsub(
        /@(aol|googlemail|gmail|hotmail|yahoo|icloud|outlook)\.(co|net|org)$/,
        "@\\1.com"
      )
  end
end
