# frozen_string_literal: true

module ImageUtils
  module_function

  def blank?(image)
    min = (0...image.bands).map { |i| image.stats.getpoint(0, i)[0] }
    max = (0...image.bands).map { |i| image.stats.getpoint(1, i)[0] }

    return true if min.all?(255) && max.all?(255)
    return true if min.all?(0) && max.all?(0)

    false
  end
end
