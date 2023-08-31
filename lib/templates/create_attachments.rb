# frozen_string_literal: true

module Templates
  module CreateAttachments
    PDF_CONTENT_TYPE = 'application/pdf'

    module_function

    def call(template, params)
      find_or_create_blobs(params).map do |blob|
        document = template.documents.create!(blob:)

        document_data = blob.download

        if blob.content_type == PDF_CONTENT_TYPE && blob.metadata['pdf'].nil?
          blob.metadata['pdf'] = { 'annotations' => Templates::BuildAnnotations.call(document_data) }
        end

        blob.save!

        Templates::ProcessDocument.call(document, document_data)
      end
    end

    def find_or_create_blobs(params)
      blobs = params[:blobs]&.map do |attrs|
        ActiveStorage::Blob.find_signed(attrs[:signed_id])
      end

      blobs || params[:files].map do |file|
        data = file.read

        if file.content_type == PDF_CONTENT_TYPE
          metadata = { 'identified' => true, 'analyzed' => true,
                       'pdf' => { 'annotations' => Templates::BuildAnnotations.call(data) } }
        end

        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(data),
          filename: file.original_filename,
          metadata:,
          content_type: file.content_type
        )
      end
    end
  end
end
