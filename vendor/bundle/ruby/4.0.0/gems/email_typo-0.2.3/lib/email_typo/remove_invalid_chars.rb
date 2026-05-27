# frozen_string_literal: true

module EmailTypo
  RemoveInvalidChars = lambda do |email|
    email
      .gsub(/(\s|[#`'"\\|])*/, "")
      .gsub(%r{/}, ".")
      .gsub(/(,|\.\.)/, ".")
      .gsub("!", "1")
      .gsub("@@", "@")
  end
end
