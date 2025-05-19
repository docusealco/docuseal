# frozen_string_literal: true

module LoadIco
  BI_RGB = 0

  module_function

  # rubocop:disable Metrics
  def call(ico_bytes)
    io = StringIO.new(ico_bytes)
    _reserved, type, count = io.read(6)&.unpack('S<S<S<')

    raise ArgumentError, 'Unable to load' unless type == 1 && count&.positive?

    ico_entries_parsed = []

    count.times do
      entry_bytes = io.read(16)

      raise ArgumentError, 'Unable to load' unless entry_bytes && entry_bytes.bytesize == 16

      width_byte, height_byte, _num_colors_palette, _rsvd_entry, _planes_icon_entry, bpp_icon_entry,
      img_data_size, img_data_offset = entry_bytes.unpack('CCCCS<S<L<L<')

      width = width_byte.zero? ? 256 : width_byte
      height = height_byte.zero? ? 256 : height_byte
      sort_bpp = bpp_icon_entry.zero? ? 32 : bpp_icon_entry

      ico_entries_parsed << {
        width: width, height: height,
        sort_bpp: sort_bpp,
        size: img_data_size, offset: img_data_offset
      }
    end

    best_entry = ico_entries_parsed.min_by { |e| [-e[:width] * e[:height], -e[:sort_bpp]] }

    raise ArgumentError, 'Unable to load' unless best_entry

    io.seek(best_entry[:offset])
    image_data_bytes = io.read(best_entry[:size])

    raise ArgumentError, 'Unable to load' unless image_data_bytes && image_data_bytes.bytesize == best_entry[:size]

    image = load_image_entry(image_data_bytes, best_entry[:width], best_entry[:height])

    raise ArgumentError, 'Unable to load' unless image

    image
  end

  def load_image_entry(image_data_bytes, ico_entry_width, ico_entry_height)
    dib_io = StringIO.new(image_data_bytes)

    dib_header_size_arr = dib_io.read(4)&.unpack('L<')
    return nil unless dib_header_size_arr

    dib_header_size = dib_header_size_arr.first
    return nil unless dib_header_size && dib_header_size >= 40

    dib_params_bytes = dib_io.read(36)
    return nil unless dib_params_bytes && dib_params_bytes.bytesize == 36

    dib_width, dib_actual_height_field, dib_planes, dib_bpp,
    dib_compression, _dib_image_size, _xpels, _ypels,
    dib_clr_used, _dib_clr_important = dib_params_bytes.unpack('l<l<S<S<L<L<l<l<L<L<')

    return nil unless dib_width && dib_actual_height_field && dib_planes && dib_bpp && dib_compression && dib_clr_used
    return nil unless dib_width == ico_entry_width

    image_pixel_height = ico_entry_height

    expected_dib_height_no_mask = image_pixel_height
    expected_dib_height_with_mask = image_pixel_height * 2
    actual_dib_pixel_rows_abs = dib_actual_height_field.abs

    unless actual_dib_pixel_rows_abs == expected_dib_height_no_mask ||
           actual_dib_pixel_rows_abs == expected_dib_height_with_mask
      return nil
    end

    return nil unless dib_planes == 1
    return nil unless dib_compression == BI_RGB
    return nil unless [1, 4, 8, 24, 32].include?(dib_bpp)

    has_and_mask = (actual_dib_pixel_rows_abs == expected_dib_height_with_mask) && (dib_bpp < 32)

    dib_io.seek(dib_header_size, IO::SEEK_SET)

    palette = []
    if dib_bpp <= 8
      num_palette_entries = dib_clr_used.zero? ? (1 << dib_bpp) : dib_clr_used
      num_palette_entries.times do
        palette_color_bytes = dib_io.read(4)
        return nil unless palette_color_bytes && palette_color_bytes.bytesize == 4

        b, g, r, _a_reserved = palette_color_bytes.unpack('CCCC')
        palette << [r, g, b, 255]
      end
    end

    xor_mask_data_offset = dib_io.pos
    xor_scanline_stride = (((dib_width * dib_bpp) + 31) / 32) * 4

    and_mask_data_offset = 0
    and_scanline_stride = 0
    if has_and_mask
      and_mask_data_offset = xor_mask_data_offset + (image_pixel_height * xor_scanline_stride)
      and_scanline_stride = (((dib_width * 1) + 31) / 32) * 4
    end

    flat_rgba_pixels = []

    (0...image_pixel_height).each do |y_row|
      y_dib_row = image_pixel_height - 1 - y_row

      dib_io.seek(xor_mask_data_offset + (y_dib_row * xor_scanline_stride))
      xor_scanline_bytes = dib_io.read(xor_scanline_stride)
      min_xor_bytes_needed = ((dib_width * dib_bpp) + 7) / 8
      return nil unless xor_scanline_bytes && xor_scanline_bytes.bytesize >= min_xor_bytes_needed

      and_mask_bits_for_row = []
      if has_and_mask
        dib_io.seek(and_mask_data_offset + (y_dib_row * and_scanline_stride))
        and_mask_scanline_bytes = dib_io.read(and_scanline_stride)
        min_and_bytes_needed = ((dib_width * 1) + 7) / 8
        return nil unless and_mask_scanline_bytes && and_mask_scanline_bytes.bytesize >= min_and_bytes_needed

        (0...dib_width).each do |x_pixel|
          byte_index = x_pixel / 8
          bit_index_in_byte = 7 - (x_pixel % 8)
          byte_val = and_mask_scanline_bytes.getbyte(byte_index)
          and_mask_bits_for_row << ((byte_val >> bit_index_in_byte) & 1)
        end
      end

      (0...dib_width).each do |x_pixel|
        r = 0
        g = 0
        b = 0
        a = 255

        case dib_bpp
        when 32
          offset = x_pixel * 4
          blue = xor_scanline_bytes.getbyte(offset)
          green = xor_scanline_bytes.getbyte(offset + 1)
          red = xor_scanline_bytes.getbyte(offset + 2)
          alpha_val = xor_scanline_bytes.getbyte(offset + 3)
          r = red
          g = green
          b = blue
          a = alpha_val
        when 24
          offset = x_pixel * 3
          blue = xor_scanline_bytes.getbyte(offset)
          green = xor_scanline_bytes.getbyte(offset + 1)
          red = xor_scanline_bytes.getbyte(offset + 2)
          r = red
          g = green
          b = blue
        when 8
          idx = xor_scanline_bytes.getbyte(x_pixel)
          r_p, g_p, b_p, a_p = palette[idx] || [0, 0, 0, 0]
          r = r_p
          g = g_p
          b = b_p
          a = a_p
        when 4
          byte_val = xor_scanline_bytes.getbyte(x_pixel / 2)
          idx = (x_pixel.even? ? (byte_val >> 4) : (byte_val & 0x0F))
          r_p, g_p, b_p, a_p = palette[idx] || [0, 0, 0, 0]
          r = r_p
          g = g_p
          b = b_p
          a = a_p
        when 1
          byte_val = xor_scanline_bytes.getbyte(x_pixel / 8)
          idx = (byte_val >> (7 - (x_pixel % 8))) & 1
          r_p, g_p, b_p, a_p = palette[idx] || [0, 0, 0, 0]
          r = r_p
          g = g_p
          b = b_p
          a = a_p
        end

        if has_and_mask && !and_mask_bits_for_row.empty?
          a = and_mask_bits_for_row[x_pixel] == 1 ? 0 : 255
        end
        flat_rgba_pixels.push(r, g, b, a)
      end
    end

    pixel_data_string = flat_rgba_pixels.pack('C*')

    expected_bytes = dib_width * image_pixel_height * 4

    return nil unless pixel_data_string.bytesize == expected_bytes && expected_bytes.positive?

    Vips::Image.new_from_memory(
      pixel_data_string,
      dib_width,
      image_pixel_height,
      4,
      :uchar
    )
  end
  # rubocop:enable Metrics
end
