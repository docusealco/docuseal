module Vips
  # How to combine values, see for example {Image#compass}.
  #
  # * `:max` take the maximum of the possible values
  # * `:sum` sum all the values
  # * `:min` take the minimum value

  class Combine < Symbol
  end
end
