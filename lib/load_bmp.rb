# frozen_string_literal: true

module LoadBmp
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

    final_pixel_data = prepare_unpadded_pixel_data_string(
      raw_pixel_data_from_file,
      header_data[:bpp],
      header_data[:width],
      header_data[:height],
      header_data[:bmp_stride]
    )

    bands = header_data[:bpp] / 8

    unless header_data[:bpp] == 24 || header_data[:bpp] == 32
      raise ArgumentError, "Conversion for #{header_data[:bpp]}-bpp BMP not implemented."
    end

    image = Vips::Image.new_from_memory(final_pixel_data, header_data[:width], header_data[:height], bands, :uchar)

    image = image.flip(:vertical) if header_data[:orientation] == -1

    image_rgb =
      if bands == 3
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

    unless [24, 32].include?(bpp)
      raise ArgumentError, "Unsupported BMP bits per pixel: #{bpp}. Only 24-bit and 32-bit are supported."
    end

    raise ArgumentError, "Unsupported BMP planes: #{planes}. Expected 1." if planes != 1

    bytes_per_pixel = bpp / 8
    row_size_unpadded = width * bytes_per_pixel
    bmp_stride = (row_size_unpadded + 3) & ~3

    {
      width:,
      height:,
      bpp:,
      pixel_data_offset:,
      bmp_stride:,
      orientation:
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
