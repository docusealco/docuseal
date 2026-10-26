# frozen_string_literal: true

module Templates
  module BuildImagePagePdf
    InvalidPng = Class.new(StandardError)

    PNG_SIGNATURE = "\x89PNG\r\n\x1a\n".b

    HEADER = "%PDF-1.4\n"
    CATALOG_OBJECT = '<< /Type /Catalog /Pages 2 0 R >>'
    PAGES_OBJECT = '<< /Type /Pages /Kids [ 3 0 R ] /Count 1 >>'

    PAGE_OBJECT_TEMPLATE =
      '<< /Type /Page /Parent 2 0 R /MediaBox [ 0 0 %<page_width>s %<page_height>s ] ' \
      '/Resources << /XObject << /Im0 4 0 R >> >> /Contents 5 0 R >>'

    IMAGE_DICT_TEMPLATE =
      '<< /Type /XObject /Subtype /Image /Width %<width>d /Height %<height>d ' \
      '/BitsPerComponent %<bit_depth>d /ColorSpace %<color_space>s /Filter /FlateDecode ' \
      '/DecodeParms << /Predictor 15 /Colors %<colors>d /BitsPerComponent %<bit_depth>d ' \
      '/Columns %<width>d >> /Length %<length>d >>'

    CONTENTS_DICT_TEMPLATE = '<< /Length %<length>d >>'
    CONTENTS_TEMPLATE = "q\n%<image_width>s 0 0 %<image_height>s %<image_x>s %<image_y>s cm\n/Im0 Do\nQ"
    INDEXED_COLOR_SPACE_TEMPLATE = '[ /Indexed /DeviceRGB %<high_value>d <%<palette>s> ]'
    STREAM_OBJECT_TEMPLATE = "%<dict>s\nstream\n%<data>s\nendstream".b
    OBJECT_TEMPLATE = "%<number>d 0 obj\n%<object>s\nendobj\n".b
    XREF_HEADER_TEMPLATE = "xref\n0 %<size>d\n0000000000 65535 f \n"
    XREF_ENTRY_TEMPLATE = "%<offset>010d 00000 n \n"
    TRAILER_TEMPLATE = "trailer\n<< /Size %<size>d /Root 1 0 R >>\nstartxref\n%<xref_offset>d\n%%%%EOF"

    module_function

    def call(png_data, page_width:, page_height:, image_box: nil)
      png = parse_png(png_data)

      raise InvalidPng, 'interlaced png is not supported' unless png[:interlace].zero?

      color_space, colors =
        case png[:color_type]
        when 0 then ['/DeviceGray', 1]
        when 2 then ['/DeviceRGB', 3]
        when 3
          raise InvalidPng, 'missing palette' if png[:palette].nil?

          [format(INDEXED_COLOR_SPACE_TEMPLATE,
                  high_value: (png[:palette].bytesize / 3) - 1,
                  palette: png[:palette].unpack1('H*')), 1]
        else
          raise InvalidPng, "unsupported color type #{png[:color_type]}"
        end

      build_pdf(png, color_space, colors,
                [page_width, page_height].map { |value| value.round(4) },
                (image_box || [0, 0, page_width, page_height]).map { |value| value.round(4) })
    end

    def parse_png(data)
      raise InvalidPng, 'not a png' unless data.start_with?(PNG_SIGNATURE)

      ihdr = nil
      palette = nil
      idat = +''.b
      pos = 8

      while pos + 8 <= data.bytesize
        length = data.byteslice(pos, 4).unpack1('N')
        type = data.byteslice(pos + 4, 4)

        case type
        when 'IHDR' then ihdr = data.byteslice(pos + 8, length)
        when 'PLTE' then palette = data.byteslice(pos + 8, length)
        when 'tRNS' then raise InvalidPng, 'transparency is not supported'
        when 'IDAT' then idat << data.byteslice(pos + 8, length)
        when 'IEND' then break
        end

        pos += 12 + length
      end

      raise InvalidPng, 'missing image data' if ihdr.nil? || ihdr.bytesize < 13 || idat.empty?

      width, height, bit_depth, color_type, _compression, _filter, interlace = ihdr.unpack('N2C5')

      { width:, height:, bit_depth:, color_type:, interlace:, palette:, idat: }
    end

    def build_pdf(png, color_space, colors, page_size, image_box)
      page_width, page_height = page_size
      image_x, image_y, image_width, image_height = image_box

      contents = format(CONTENTS_TEMPLATE, image_x:, image_y:, image_width:, image_height:)

      image_dict = format(IMAGE_DICT_TEMPLATE,
                          width: png[:width], height: png[:height], bit_depth: png[:bit_depth],
                          color_space:, colors:, length: png[:idat].bytesize)

      objects = [
        CATALOG_OBJECT,
        PAGES_OBJECT,
        format(PAGE_OBJECT_TEMPLATE, page_width:, page_height:),
        format(STREAM_OBJECT_TEMPLATE, dict: image_dict, data: png[:idat]),
        format(STREAM_OBJECT_TEMPLATE, dict: format(CONTENTS_DICT_TEMPLATE, length: contents.bytesize),
                                       data: contents)
      ]

      pdf = +HEADER.b
      offsets = []

      objects.each_with_index do |object, index|
        offsets << pdf.bytesize

        pdf << format(OBJECT_TEMPLATE, number: index + 1, object:)
      end

      xref_offset = pdf.bytesize

      pdf << format(XREF_HEADER_TEMPLATE, size: objects.size + 1).b

      offsets.each { |offset| pdf << format(XREF_ENTRY_TEMPLATE, offset:).b }

      pdf << format(TRAILER_TEMPLATE, size: objects.size + 1, xref_offset:).b
    end
  end
end
