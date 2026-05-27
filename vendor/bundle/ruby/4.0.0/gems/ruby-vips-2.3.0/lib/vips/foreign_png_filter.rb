module Vips
  # The set of filters for PNG save. See http://www.w3.org/TR/PNG-Filters.html
  #
  # *   `:none` no filtering
  # *   `:sub` difference to the left
  # *   `:up` difference up
  # *   `:avg` average of left and up
  # *   `:paeth` pick best neighbor predictor automatically
  # *   `:all` adaptive

  class ForeignPngFilter < Symbol
  end
end
