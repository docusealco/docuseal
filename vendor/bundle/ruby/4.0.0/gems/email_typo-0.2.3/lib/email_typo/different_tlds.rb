# frozen_string_literal: true

module EmailTypo
  DifferentTlds = lambda do |email|
    email
      .gsub(/\.(o\.uk|co\.k|couk|co\.u[kmnlj]{0,2})$/, ".co.uk")
      .gsub(/\.(cojp|co\.lp|co\.p)$/, ".co.jp")
      .gsub(/\.(com?br|com?\.[bv]r+)$/, ".com.br")
      .gsub(/\.(r+(u+(?!n).|y)|r)$/, ".ru")
      .gsub(/\.i+t+$/, ".it")
      .gsub(/\.f+[re]+$/, ".fr")
      .gsub(/\.de+(?!v).$/, ".de")
      .gsub(/\.jn$/, ".in")
      .gsub(/\.lde$/, ".de")
      .gsub(/\.oprg$/, ".org")
      .gsub(/\.gob(\b|\.)/, ".gov")
      .gsub(/\.edi?(\b|\.)/, ".edu")
      .gsub(/\.mx.{1,2}$/, ".mx")
      .gsub(/\.[com.]{2,3}ar$/, ".com.ar")
      .gsub(/\.[com.]{2,3}au$/, ".com.au")
  end
end
