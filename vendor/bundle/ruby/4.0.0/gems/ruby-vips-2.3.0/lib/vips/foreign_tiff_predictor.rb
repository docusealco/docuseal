module Vips
  # The predictor can help deflate and lzw compression.
  #
  # *   `:none` no prediction
  # *   `:horizontal` horizontal differencing
  # *   `:float` float predictor

  class ForeignTiffPredictor < Symbol
  end
end
