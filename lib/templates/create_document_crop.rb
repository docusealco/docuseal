# frozen_string_literal: true

module Templates
  module CreateDocumentCrop
    MAX_SCAN_SIZE = 1400

    module_function

    def call(template, attachment, params)
      scan = params[:scan]

      bytes, width, height = Leptonica.crop_document(attachment.download, params[:corners].map(&:to_h),
                                                     scan:,
                                                     rotate: params[:rotate]&.to_i,
                                                     flip_h: params[:flip_h],
                                                     flip_v: params[:flip_v])

      image = load_image(bytes, width, height)
      image = pad_scan_image(image, template.account) if scan

      data = scan ? encode_png(image) : encode_jpeg(image)

      create_document!(template, attachment, data, scan)
    end

    def create_document!(template, attachment, data, scan)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(data),
        filename: "#{attachment.filename.base}.#{scan ? 'png' : 'jpg'}",
        metadata: { identified: true, analyzed: true },
        content_type: scan ? 'image/png' : 'image/jpeg'
      )

      document = template.documents.create!(blob:)

      Templates::ProcessDocument.call(document, data)

      document
    end

    def load_image(bytes, width, height)
      Vips::Image.new_from_memory_copy(bytes, width, height, 4, :uchar)
                 .extract_band(0, n: 3)
                 .copy(interpretation: :srgb)
    end

    def pad_scan_image(image, account)
      scale = MAX_SCAN_SIZE / [image.width, image.height].max.to_f
      image = image.resize(scale) if scale < 1

      base_size = Templates::ModifyDocuments.default_page_size(account)
      page_width, page_height = image.width > image.height ? base_size.reverse : base_size

      target_width = [image.width, (image.height * page_width / page_height.to_f).round].max
      target_height = [image.height, (image.width * page_height / page_width.to_f).round].max

      image.gravity('centre', target_width, target_height, extend: :background, background: 255)
    end

    def encode_png(image)
      image.write_to_buffer(Templates::ProcessDocument::FORMAT,
                            compression: 6, filter: 0, bitdepth: 4, palette: true, dither: 0, strip: true)
    end

    def encode_jpeg(image)
      image.write_to_buffer('.jpg', Q: 90, strip: true)
    end
  end
end
