# frozen_string_literal: true

module Templates
  module CreateAttachments
    PDF_CONTENT_TYPE = 'application/pdf'
    ANNOTATIONS_SIZE_LIMIT = 6.megabytes
    InvalidFileType = Class.new(StandardError)
    PdfEncrypted = Class.new(StandardError)

    module_function

    def call(template, params)
      Array.wrap(params[:files].presence || params[:file]).map do |file|
        if file.content_type.exclude?('image') && file.content_type != PDF_CONTENT_TYPE
          file, document_data = handle_file_types(file)
        end

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

        Templates::ProcessDocument.call(document, document_data)
      end
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

    def handle_file_types(_file)
      raise InvalidFileType, blob.content_type
    end
  end
end
