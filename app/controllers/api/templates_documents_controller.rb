# frozen_string_literal: true

module Api
  class TemplatesDocumentsController < ApiBaseController
    def create
      return head :unprocessable_entity if params[:blobs].blank? && params[:files].blank?

      @template = current_account.templates.find(params[:template_id])

      documents =
        find_or_create_blobs.map do |blob|
          document = @template.documents.create!(blob:)

          Templates::ProcessDocument.call(document)
        end

      schema = documents.map do |doc|
        { attachment_uuid: doc.uuid, name: doc.filename.base }
      end

      render json: {
        schema:,
        documents: documents.as_json(
          include: {
            preview_images: { methods: %i[url metadata filename] }
          }
        )
      }
    end

    private

    def find_or_create_blobs
      blobs = params[:blobs]&.map do |attrs|
        ActiveStorage::Blob.find_signed(attrs[:signed_id])
      end

      blobs || params[:files].map do |file|
        ActiveStorage::Blob.create_and_upload!(io: file.open,
                                               filename: file.original_filename,
                                               content_type: file.content_type)
      end
    end
  end
end
