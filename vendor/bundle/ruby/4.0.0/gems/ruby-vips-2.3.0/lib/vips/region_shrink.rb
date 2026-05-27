module Vips
  # ow to calculate the output pixels when shrinking a 2x2 region.
  #
  # *   `:mean` use the average
  # *   `:median` use the median
  # *   `:mode` use the mode
  # *   `:max` use the maximum
  # *   `:min` use the minimum
  # *   `:nearest` use the top-left pixel

  class RegionShrink < Symbol
  end
end
