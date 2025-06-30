# frozen_string_literal: true

module Templates
  module ProcessDocument
    DPI = 200
    FORMAT = '.png'
    ATTACHMENT_NAME = 'preview_images'

    BMP_REGEXP = %r{\Aimage/(?:bmp|x-bmp|x-ms-bmp)\z}
    PDF_CONTENT_TYPE = 'application/pdf'
    CONCURRENCY = 2
    Q = 95
    JPEG_Q = ENV.fetch('PAGE_QUALITY', '35').to_i
    MAX_WIDTH = 1400
    MAX_NUMBER_OF_PAGES_PROCESSED = 15
    MAX_FLATTEN_FILE_SIZE = 20.megabytes
    GENERATE_PREVIEW_SIZE_LIMIT = 50.megabytes

    module_function

    def call(attachment, data, extract_fields: false, max_pages: MAX_NUMBER_OF_PAGES_PROCESSED)
      if attachment.content_type == PDF_CONTENT_TYPE
        if extract_fields && data.size < MAX_FLATTEN_FILE_SIZE
          pdf = HexaPDF::Document.new(io: StringIO.new(data))

          fields = Templates::FindAcroFields.call(pdf, attachment, data)
        end

        generate_pdf_preview_images(attachment, data, pdf, max_pages:)

        attachment.metadata['pdf']['fields'] = fields if fields
      elsif attachment.image?
        generate_preview_image(attachment, data)
      end

      attachment
    end

    def process(attachment, data, extract_fields: false)
      if attachment.content_type == PDF_CONTENT_TYPE && extract_fields && data.size < MAX_FLATTEN_FILE_SIZE
        pdf = HexaPDF::Document.new(io: StringIO.new(data))

        fields = Templates::FindAcroFields.call(pdf, attachment, data)
      end

      pdf ||= HexaPDF::Document.new(io: StringIO.new(data))

      number_of_pages = pdf.pages.size

      attachment.metadata['pdf'] ||= {}
      attachment.metadata['pdf']['number_of_pages'] = number_of_pages
      attachment.metadata['pdf']['fields'] = fields if fields

      attachment
    end

    def generate_preview_image(attachment, data)
      ActiveStorage::Attachment.where(name: ATTACHMENT_NAME, record: attachment).destroy_all

      image =
        if BMP_REGEXP.match?(attachment.content_type)
          LoadBmp.call(data)
        else
          Vips::Image.new_from_buffer(data, '')
        end

      image = image.autorot.resize(MAX_WIDTH / image.width.to_f)

      bitdepth = 2**image.stats.to_a[1..3].pluck(2).uniq.size

      io = StringIO.new(image.write_to_buffer(FORMAT, compression: 7, filter: 0, bitdepth:,
                                                      palette: true, Q: Q, dither: 0))

      ActiveStorage::Attachment.create!(
        blob: ActiveStorage::Blob.create_and_upload!(
          io:, filename: "0#{FORMAT}",
          metadata: { analyzed: true, identified: true, width: image.width, height: image.height }
        ),
        name: ATTACHMENT_NAME,
        record: attachment
      )
    end

    def generate_pdf_preview_images(attachment, data, pdf = nil, max_pages: MAX_NUMBER_OF_PAGES_PROCESSED)
      ActiveStorage::Attachment.where(name: ATTACHMENT_NAME, record: attachment).destroy_all

      pdf ||= HexaPDF::Document.new(io: StringIO.new(data))
      number_of_pages = pdf.pages.size

      data = maybe_flatten_form(data, pdf)

      attachment.metadata['pdf'] ||= {}
      attachment.metadata['pdf']['number_of_pages'] = number_of_pages

      ApplicationRecord.no_touching do
        attachment.save!
      end

      max_pages_to_process = data.size < GENERATE_PREVIEW_SIZE_LIMIT ? max_pages : 1

      generate_document_preview_images(attachment, data, (0..[number_of_pages - 1, max_pages_to_process].min))
    end

    def generate_document_preview_images(attachment, data, range, concurrency: CONCURRENCY)
      doc = Pdfium::Document.open_bytes(data)

      pool = Concurrent::FixedThreadPool.new(concurrency)

      promises =
        range.map do |page_number|
          Concurrent::Promise.execute(executor: pool) { build_and_upload_blob(doc, page_number) }
        end

      Concurrent::Promise.zip(*promises).value!.each do |blob|
        next unless blob

        ApplicationRecord.no_touching do
          ActiveStorage::Attachment.create!(
            blob:,
            name: ATTACHMENT_NAME,
            record: attachment
          )
        end
      end
    ensure
      doc&.close
      pool&.kill
    end

    def build_and_upload_blob(doc, page_number, format = FORMAT)
      doc_page = doc.get_page(page_number)

      data, width, height = doc_page.render_to_bitmap(width: MAX_WIDTH)

      page = Vips::Image.new_from_memory(data, width, height, 4, :uchar)

      page = page.copy(interpretation: :srgb)

      data =
        if format == FORMAT
          bitdepth = 2**page.stats.to_a[1..3].pluck(2).uniq.size

          page.write_to_buffer(format, compression: 7, filter: 0, bitdepth:,
                                       palette: true, Q: Q, dither: 0)
        else
          page.write_to_buffer(format, interlace: true, Q: JPEG_Q)
        end

      blob = ActiveStorage::Blob.new(
        filename: "#{page_number}#{format}",
        metadata: { analyzed: true, identified: true, width: page.width, height: page.height }
      )

      blob.upload(StringIO.new(data))

      blob
    rescue Vips::Error, Pdfium::PdfiumError => e
      Rollbar.warning(e) if defined?(Rollbar)

      nil
    ensure
      doc_page&.close
    end

    def maybe_flatten_form(data, pdf)
      return data if data.size > MAX_FLATTEN_FILE_SIZE
      return data if pdf.acro_form.blank?

      io = StringIO.new

      pdf.acro_form.each_field do |field|
        next if field.field_type != :Ch ||
                field[:Opt].blank? ||
                %i[combo_box editable_combo_box].exclude?(field.concrete_field_type) ||
                !field.field_value.to_s.match?(FindAcroFields::SELECT_PLACEHOLDER_REGEXP)

        field[:V] = ''
      end

      pdf.acro_form.create_appearances(force: true) if pdf.acro_form[:NeedAppearances]
      pdf.acro_form.flatten

      pdf.write(io, incremental: false, validate: false)

      io.string
    rescue StandardError
      raise if Rails.env.development?

      data
    end

    def normalize_attachment_fields(template, attachments = template.documents)
      attachments.flat_map do |a|
        pdf_fields = a.metadata['pdf'].delete('fields').to_a if a.metadata['pdf'].present?

        next [] if pdf_fields.blank?

        pdf_fields.each { |f| f['submitter_uuid'] = template.submitters.first['uuid'] }

        pdf_fields
      end
    end

    def generate_pdf_preview_from_file(attachment, file_path, page_number)
      doc = Pdfium::Document.open_file(file_path)

      blob = build_and_upload_blob(doc, page_number, '.jpeg')

      ApplicationRecord.no_touching do
        ActiveStorage::Attachment.create!(
          blob: blob,
          name: ATTACHMENT_NAME,
          record: attachment
        )
      end
    ensure
      doc&.close
    end
  end
end
