# frozen_string_literal: true

module EmailTypo
  DotNet = lambda do |email|
    email
      .gsub(/\.(nte*|n*et*|ney)$/, ".net")
      .gsub(/\.met$/, ".net")
  end
end
