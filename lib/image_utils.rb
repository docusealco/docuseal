# frozen_string_literal: true

module ImageUtils
  module_function

  def blank?(image)
    stats = image.stats

    min = (0...image.bands).map { |i| stats.getpoint(0, i)[0] }
    max = (0...image.bands).map { |i| stats.getpoint(1, i)[0] }

    return true if min.all?(255) && max.all?(255)
    return true if min.all?(0) && max.all?(0)

    false
  end

  def error?(image)
    image = image.crop(0, 0, image.width / 4, 2)

    row1, row2 = image.to_a

    row1[3..] == row2[..-4] && row1.each_cons(2).none? { |a, b| a == b }
  end
end
