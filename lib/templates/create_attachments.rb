# frozen_string_literal: true

module Templates
  module CreateAttachments
    PDF_CONTENT_TYPE = 'application/pdf'
    ZIP_CONTENT_TYPE = 'application/zip'
    X_ZIP_CONTENT_TYPE = 'application/x-zip-compressed'
    JSON_CONTENT_TYPE = 'application/json'
    DOCUMENT_EXTENSIONS = %w[.docx .doc .xlsx .xls .odt .rtf].freeze

    DOCUMENT_CONTENT_TYPES = %w[
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      application/msword
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      application/vnd.ms-excel
      application/vnd.oasis.opendocument.text
      application/rtf
    ].freeze

    ANNOTATIONS_SIZE_LIMIT = 6.megabytes
    MAX_ZIP_SIZE = 100.megabytes
    InvalidFileType = Class.new(StandardError)
    PdfEncrypted = Class.new(StandardError)

    module_function

    def call(template, params, extract_fields: false)
      extract_zip_files(params[:files].presence || params[:file]).flat_map do |file|
        handle_file_types(template, file, params, extract_fields:)
      end
    end

    def handle_pdf_or_image(template, file, document_data = nil, params = {}, extract_fields: false)
      document_data ||= file.read

      if file.content_type == PDF_CONTENT_TYPE
        document_data = maybe_decrypt_pdf_or_raise(document_data, params)

        annotations =
          document_data.size < ANNOTATIONS_SIZE_LIMIT ? Templates::BuildAnnotations.call(document_data) : []
      end

      sha256 = Base64.urlsafe_encode64(Digest::SHA256.digest(document_data))

      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(document_data),
        filename: file.original_filename,
        metadata: {
          identified: file.content_type == PDF_CONTENT_TYPE,
          analyzed: file.content_type == PDF_CONTENT_TYPE,
          pdf: { annotations: }.compact_blank, sha256:
        }.compact_blank,
        content_type: file.content_type
      )

      document = template.documents.create!(blob:)

      Templates::ProcessDocument.call(document, document_data, extract_fields:)
    end

    def maybe_decrypt_pdf_or_raise(data, params)
      if data.size < ANNOTATIONS_SIZE_LIMIT && PdfUtils.encrypted?(data)
        PdfUtils.decrypt(data, params[:password])
      else
        data
      end
    rescue HexaPDF::EncryptionError
      raise PdfEncrypted
    end

    def extract_zip_files(files)
      extracted_files = []

      Array.wrap(files).each do |file|
        if file.content_type == ZIP_CONTENT_TYPE || file.content_type == X_ZIP_CONTENT_TYPE
          total_size = 0

          Zip::File.open(file.tempfile).each do |entry|
            next if entry.directory?

            total_size += entry.size

            raise InvalidFileType, 'zip_too_large' if total_size > MAX_ZIP_SIZE

            tempfile = Tempfile.new(entry.name)
            tempfile.binmode
            entry.get_input_stream { |in_stream| IO.copy_stream(in_stream, tempfile) }
            tempfile.rewind

            type = Marcel::MimeType.for(tempfile, name: entry.name)

            next if type.exclude?('image') &&
                    type != PDF_CONTENT_TYPE &&
                    type != JSON_CONTENT_TYPE &&
                    DOCUMENT_CONTENT_TYPES.exclude?(type)

            extracted_files << ActionDispatch::Http::UploadedFile.new(
              filename: File.basename(entry.name),
              type:,
              tempfile:
            )
          end
        else
          extracted_files << file
        end
      end

      extracted_files
    end

    def handle_file_types(template, file, params, extract_fields:)
      if file.content_type.include?('image') || file.content_type == PDF_CONTENT_TYPE
        return handle_pdf_or_image(template, file, file.read, params, extract_fields:)
      end

      raise InvalidFileType, file.content_type
    end
  end
end
