# frozen_string_literal: true

module LoadBmp
  BPPS = [1, 4, 8, 24, 32].freeze

  module_function

  # rubocop:disable Metrics
  def call(bmp_bytes)
    bmp_bytes = bmp_bytes.b

    header_data = parse_bmp_headers(bmp_bytes)

    raw_pixel_data_from_file = extract_raw_pixel_data_blob(
      bmp_bytes,
      header_data[:pixel_data_offset],
      header_data[:bmp_stride],
      header_data[:height]
    )

    if header_data[:bpp] <= 8
      final_pixel_data = decode_indexed_pixel_data(
        raw_pixel_data_from_file,
        header_data[:bpp],
        header_data[:width],
        header_data[:height],
        header_data[:bmp_stride],
        header_data[:color_table]
      )
      bands = 3
    else
      final_pixel_data = prepare_unpadded_pixel_data_string(
        raw_pixel_data_from_file,
        header_data[:bpp],
        header_data[:width],
        header_data[:height],
        header_data[:bmp_stride]
      )
      bands = header_data[:bpp] / 8
    end

    image = Vips::Image.new_from_memory(final_pixel_data, header_data[:width], header_data[:height], bands, :uchar)

    image = image.flip(:vertical) if header_data[:orientation] == -1

    image_rgb =
      if header_data[:bpp] <= 8
        image
      elsif bands == 3
        image.recomb(band3_recomb)
      elsif bands == 4
        image.recomb(band4_recomb)
      end

    image_rgb = image_rgb.copy(interpretation: :srgb) if image_rgb.interpretation != :srgb

    image_rgb
  end

  def parse_bmp_headers(bmp_bytes)
    raise ArgumentError, 'BMP data too short for file header (14 bytes).' if bmp_bytes.bytesize < 14

    signature, pixel_data_offset = bmp_bytes.unpack('a2@10L<')

    raise ArgumentError, "Not a valid BMP file (invalid signature 'BM')." if signature != 'BM'

    raise ArgumentError, 'BMP data too short for info header size field (4 bytes).' if bmp_bytes.bytesize < (14 + 4)

    info_header_size = bmp_bytes.unpack1('@14L<')

    min_expected_info_header_size = 40

    if info_header_size < min_expected_info_header_size
      raise ArgumentError,
            "Unsupported BMP info header size: #{info_header_size}. Expected at least #{min_expected_info_header_size}."
    end

    header_and_info_header_min_bytes = 14 + min_expected_info_header_size

    if bmp_bytes.bytesize < header_and_info_header_min_bytes
      raise ArgumentError,
            'BMP data too short for essential BITMAPINFOHEADER fields ' \
            "(requires #{header_and_info_header_min_bytes} bytes total)."
    end

    _header_size_check, width, raw_height_from_header, planes, bpp, compression =
      bmp_bytes.unpack('@14L<l<l<S<S<L<')

    height = 0
    orientation = -1

    if raw_height_from_header.negative?
      height = -raw_height_from_header
      orientation = 1
    else
      height = raw_height_from_header
    end

    raise ArgumentError, 'BMP width must be positive.' if width <= 0
    raise ArgumentError, 'BMP height must be positive.' if height <= 0

    if compression != 0
      raise ArgumentError,
            "Unsupported BMP compression type: #{compression}. Only uncompressed (0) is supported."
    end

    if BPPS.exclude?(bpp)
      raise ArgumentError, "Unsupported BMP bits per pixel: #{bpp}. Only 1, 4, 8, 24, and 32-bit are supported."
    end

    raise ArgumentError, "Unsupported BMP planes: #{planes}. Expected 1." if planes != 1

    bmp_stride = (((width * bpp) + 31) / 32) * 4

    color_table = nil

    if bpp <= 8
      num_colors = 1 << bpp
      color_table_offset = 14 + info_header_size
      color_table_size = num_colors * 4

      if bmp_bytes.bytesize < color_table_offset + color_table_size
        raise ArgumentError, 'BMP data too short for color table.'
      end

      color_table = Array.new(num_colors) do |i|
        offset = color_table_offset + (i * 4)
        b, g, r = bmp_bytes.unpack("@#{offset}CCC")
        [r, g, b]
      end
    end

    {
      width:,
      height:,
      bpp:,
      pixel_data_offset:,
      bmp_stride:,
      orientation:,
      color_table:
    }
  end

  def extract_raw_pixel_data_blob(bmp_bytes, pixel_data_offset, bmp_stride, height)
    expected_pixel_data_size = bmp_stride * height

    if pixel_data_offset + expected_pixel_data_size > bmp_bytes.bytesize
      actual_available = bmp_bytes.bytesize - pixel_data_offset
      actual_available = 0 if actual_available.negative?
      raise ArgumentError,
            "Pixel data segment (offset #{pixel_data_offset}, expected size #{expected_pixel_data_size}) " \
            "exceeds BMP file size (#{bmp_bytes.bytesize}). " \
            "Only #{actual_available} bytes available after offset."
    end

    raw_pixel_data_from_file = bmp_bytes.byteslice(pixel_data_offset, expected_pixel_data_size)

    if raw_pixel_data_from_file.nil? || raw_pixel_data_from_file.bytesize < expected_pixel_data_size
      raise ArgumentError,
            "Extracted pixel data is smaller (#{raw_pixel_data_from_file&.bytesize || 0} bytes) " \
            "than expected (#{expected_pixel_data_size} bytes based on stride and height)."
    end

    raw_pixel_data_from_file
  end

  def prepare_unpadded_pixel_data_string(raw_pixel_data_from_file, bpp, width, height, bmp_stride)
    bytes_per_pixel = bpp / 8
    actual_row_width_bytes = width * bytes_per_pixel

    unpadded_rows = Array.new(height)
    current_offset_in_blob = 0

    height.times do |i|
      if current_offset_in_blob + actual_row_width_bytes > raw_pixel_data_from_file.bytesize
        raise ArgumentError,
              "Not enough data in pixel blob for row #{i}. Offset #{current_offset_in_blob}, " \
              "row width #{actual_row_width_bytes}, blob size #{raw_pixel_data_from_file.bytesize}"
      end

      unpadded_row_slice = raw_pixel_data_from_file.byteslice(current_offset_in_blob, actual_row_width_bytes)

      if unpadded_row_slice.nil? || unpadded_row_slice.bytesize < actual_row_width_bytes
        raise ArgumentError, "Failed to slice a full unpadded row from pixel data blob for row #{i}."
      end

      unpadded_rows[i] = unpadded_row_slice
      current_offset_in_blob += bmp_stride
    end

    unpadded_rows.join
  end

  def decode_indexed_pixel_data(raw_data, bpp, width, height, bmp_stride, color_table)
    palette = color_table.map { |r, g, b| [r, g, b].pack('CCC') }

    output = String.new(capacity: width * height * 3)

    height.times do |y|
      row_offset = y * bmp_stride

      case bpp
      when 1
        width.times do |x|
          byte_val = raw_data.getbyte(row_offset + (x >> 3))
          index = (byte_val >> (7 - (x & 7))) & 0x01
          output << palette[index]
        end
      when 4
        width.times do |x|
          byte_val = raw_data.getbyte(row_offset + (x >> 1))
          index = x.even? ? (byte_val >> 4) & 0x0F : byte_val & 0x0F
          output << palette[index]
        end
      when 8
        width.times do |x|
          output << palette[raw_data.getbyte(row_offset + x)]
        end
      end
    end

    output
  end

  def band3_recomb
    @band3_recomb ||=
      Vips::Image.new_from_array(
        [
          [0, 0, 1],
          [0, 1, 0],
          [1, 0, 0]
        ]
      )
  end

  def band4_recomb
    @band4_recomb ||= Vips::Image.new_from_array(
      [
        [0, 0, 1, 0],
        [0, 1, 0, 0],
        [1, 0, 0, 0]
      ]
    )
  end
  # rubocop:enable Metrics
end
