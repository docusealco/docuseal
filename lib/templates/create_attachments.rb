# frozen_string_literal: true

module Templates
  module CreateAttachments
    PDF_CONTENT_TYPE = 'application/pdf'
    ANNOTATIONS_SIZE_LIMIT = 6.megabytes
    InvalidFileType = Class.new(StandardError)
    PdfEncrypted = Class.new(StandardError)

    module_function

    def call(template, params)
      find_or_create_blobs(params).map do |blob|
        document_data = blob.download

        if !blob.image? && blob.content_type != PDF_CONTENT_TYPE
          blob, document_data = handle_file_types(blob, document_data)
        end

        document = template.documents.create!(blob:)

        if blob.content_type == PDF_CONTENT_TYPE && blob.metadata['pdf'].nil?
          data = maybe_decrypt_pdf_or_raise(document_data, params)

          if data != document_data
            blob = ActiveStorage::Blob.create_and_upload!(
              io: StringIO.new(new_data), filename: blob.filename
            )
            document_data = data
          end

          annotations =
            document_data.size > ANNOTATIONS_SIZE_LIMIT ? [] : Templates::BuildAnnotations.call(document_data)

          blob.metadata['pdf'] = { 'annotations' => annotations }
          blob.metadata['sha256'] = Base64.urlsafe_encode64(Digest::SHA256.digest(document_data))
        end

        blob.save!

        Templates::ProcessDocument.call(document, document_data)
      end
    end

    def find_or_create_blobs(params)
      params[:files].map do |file|
        data = file.read

        if file.content_type == PDF_CONTENT_TYPE
          data = maybe_decrypt_pdf_or_raise(data, params)

          annotations = data.size > ANNOTATIONS_SIZE_LIMIT ? [] : Templates::BuildAnnotations.call(data)
          metadata = { 'identified' => true, 'analyzed' => true,
                       'sha256' => Base64.urlsafe_encode64(Digest::SHA256.digest(data)),
                       'pdf' => { 'annotations' => annotations } }
        end

        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(data),
          filename: file.original_filename,
          metadata:,
          content_type: file.content_type
        )
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

    def handle_file_types(_document_data, blob)
      raise InvalidFileType, blob.content_type
    end
  end
end
