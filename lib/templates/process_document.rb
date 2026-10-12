# frozen_string_literal: true

module Templates
  module ProcessDocument
    DPI = 200
    FORMAT = '.png'
    PREVIEW_FORMAT = '.jpg'
    ATTACHMENT_NAME = 'preview_images'

    PDF_CONTENT_TYPE = 'application/pdf'
    CONCURRENCY = 2
    Q = 95
    JPEG_Q = ENV.fetch('PAGE_QUALITY', '35').to_i
    MAX_WIDTH = 1400
    MAX_NUMBER_OF_PAGES_PROCESSED = 15
    MAX_FLATTEN_FILE_SIZE = 20.megabytes
    GENERATE_PREVIEW_SIZE_LIMIT = 50.megabytes
    US_LETTER_SIZE = { 'width' => MAX_WIDTH, 'height' => 1812 }.freeze

    module_function

    def call(attachment, data, extract_fields: false, max_pages: MAX_NUMBER_OF_PAGES_PROCESSED, doc: nil)
      if attachment.content_type == PDF_CONTENT_TYPE
        if extract_fields && data.size < MAX_FLATTEN_FILE_SIZE
          fields = Templates::FindPdfiumAcroFields.call(attachment, doc, data)
        end

        generate_pdf_preview_images(attachment, data, max_pages:, doc:)

        attachment.metadata['pdf']['fields'] = fields if fields
      elsif attachment.image?
        generate_preview_image(attachment, data)
      end

      attachment
    end

    def process(attachment, data, doc:, extract_fields: false)
      if attachment.content_type == PDF_CONTENT_TYPE && extract_fields && data.size < MAX_FLATTEN_FILE_SIZE
        fields = Templates::FindPdfiumAcroFields.call(attachment, doc, data)
      end

      attachment.metadata['pdf'] ||= {}
      attachment.metadata['pdf']['number_of_pages'] = doc.page_count
      attachment.metadata['pdf']['fields'] = fields if fields

      attachment
    end

    def generate_preview_image(attachment, data)
      ActiveStorage::Attachment.where(name: ATTACHMENT_NAME, record: attachment).destroy_all

      image = ImageUtils.load_vips(data, content_type: attachment.content_type, autorot: true)
      image = image.resize(MAX_WIDTH / image.width.to_f)

      bitdepth = 2**image.stats.to_a[1..3].pluck(2).uniq.size

      io = StringIO.new(image.write_to_buffer(FORMAT, compression: 6, filter: 0, bitdepth:,
                                                      palette: true, Q: Q, dither: 0, strip: true))

      ActiveStorage::Attachment.create!(
        blob: ActiveStorage::Blob.create_and_upload!(
          io:, filename: "0#{FORMAT}",
          metadata: { analyzed: true, identified: true, width: image.width, height: image.height }
        ),
        name: ATTACHMENT_NAME,
        record: attachment
      )
    end

    def generate_pdf_preview_images(attachment, data, doc:, max_pages: MAX_NUMBER_OF_PAGES_PROCESSED)
      ActiveStorage::Attachment.where(name: ATTACHMENT_NAME, record: attachment).destroy_all

      number_of_pages = doc.page_count

      attachment.metadata['pdf'] ||= {}
      attachment.metadata['pdf']['number_of_pages'] = number_of_pages

      ApplicationRecord.no_touching do
        attachment.save!
      end

      max_pages_to_process = data.size < GENERATE_PREVIEW_SIZE_LIMIT ? max_pages : 1

      generate_document_preview_images(attachment, 0..[number_of_pages - 1, max_pages_to_process].min, doc:)
    end

    def generate_document_preview_images(attachment, range, doc:, concurrency: CONCURRENCY)
      flatten_pages = doc.form?

      pool = Concurrent::FixedThreadPool.new(concurrency)

      blobs =
        range.each_slice(concurrency).flat_map do |page_numbers|
          slice_blobs = generate_slice_blobs(doc, page_numbers, pool:, flatten_pages:)

          # Free the slice's vips copies now: an idle process never collects them, and the next slice adds its own.
          GC.start

          slice_blobs
        end

      blobs.each do |blob|
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
      pool&.kill
    end

    def generate_slice_blobs(doc, page_numbers, pool:, flatten_pages:)
      promises =
        page_numbers.map do |page_number|
          image = render_page_image(doc, page_number, flatten_pages:)

          Concurrent::Promise.execute(executor: pool) { build_and_upload_blob(image, page_number) }
        end

      Concurrent::Promise.zip(*promises).value!
    end

    def render_page_image(doc, page_number, flatten_pages:)
      doc_page = doc.get_page(page_number)

      hide_placeholder_widgets(doc_page, hide_empty: !flatten_pages)
      doc_page.flatten if flatten_pages

      bytes, width, height = doc_page.render_to_bitmap(width: MAX_WIDTH)

      image = Vips::Image.new_from_memory_copy(bytes, width, height, 4, :uchar)

      # Vips holds its own copy: drop the 11 MB bitmap String now instead of at the next GC.
      bytes.clear

      image
    ensure
      doc_page&.close
    end

    def hide_placeholder_widgets(page, hide_empty: true)
      page.annotations.each do |annotation|
        next unless annotation.widget?

        page.with_annotation(annotation.index) do |handle|
          next if handle.field_type != Pdfium::FPDF_FORMFIELD_COMBOBOX

          value = handle.field_value.to_s

          if value.blank?
            next unless hide_empty
          elsif handle.option_labels.blank? ||
                !value.match?(FindPdfiumAcroFields::SELECT_PLACEHOLDER_REGEXP)
            next
          end

          handle.hide!
        end
      end
    end

    def build_and_upload_blob(image, page_number, format = FORMAT)
      image = image.copy(interpretation: :srgb)

      data =
        if format == FORMAT
          bitdepth = 2**image.stats.to_a[1..3].pluck(2).uniq.size

          image.write_to_buffer(format, compression: 6, filter: 0, bitdepth:,
                                        palette: true, Q: Q, dither: 0)
        else
          image.write_to_buffer(format, interlace: true, Q: JPEG_Q)
        end

      blob = ActiveStorage::Blob.new(
        filename: "#{page_number}#{format}",
        metadata: { analyzed: true, identified: true, width: image.width, height: image.height }
      )

      blob.upload(StringIO.new(data))

      blob
    end

    def normalize_attachment_fields(template, attachments = template.documents)
      attachments.flat_map do |a|
        pdf_fields = a.metadata['pdf'].delete('fields').to_a if a.metadata['pdf'].present?

        next [] if pdf_fields.blank?

        pdf_fields.each { |f| f['submitter_uuid'] = template.submitters.first['uuid'] }

        pdf_fields
      end
    end

    def generate_pdf_preview_from_io(attachment, io, page_number)
      doc = Pdfium::Document.open_io(io)

      doc_page = doc.get_page(page_number)

      bytes, width, height = doc_page.render_to_bitmap(width: MAX_WIDTH)

      doc_page.close

      image = Vips::Image.new_from_memory_copy(bytes, width, height, 4, :uchar)

      blob = build_and_upload_blob(image, page_number, PREVIEW_FORMAT)

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
