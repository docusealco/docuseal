# frozen_string_literal: true

module ImageUtils
  ICO_REGEXP = %r{\Aimage/(?:x-icon|vnd\.microsoft\.icon)\z}
  BMP_REGEXP = %r{\Aimage/(?:bmp|x-bmp|x-ms-bmp)\z}

  module_function

  def load_vips(data, content_type: nil, autorot: false)
    content_type ||= Marcel::MimeType.for(data)

    if ICO_REGEXP.match?(content_type)
      LoadIco.call(data)
    elsif BMP_REGEXP.match?(content_type)
      LoadBmp.call(data)
    else
      image = Vips::Image.new_from_buffer(data, '')

      autorot ? image.autorot : image
    end
  end

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
