# frozen_string_literal: true

module Api
  class TemplatesDocumentsController < ApiBaseController
    load_and_authorize_resource :template

    def create
      return head :unprocessable_entity if params[:blobs].blank? && params[:files].blank?

      documents = Templates::CreateAttachments.call(@template, params)

      schema = documents.map do |doc|
        { attachment_uuid: doc.uuid, name: doc.filename.base }
      end

      render json: {
        schema:,
        documents: documents.as_json(
          methods: [:metadata],
          include: {
            preview_images: { methods: %i[url metadata filename] }
          }
        )
      }
    rescue Templates::CreateAttachments::PdfEncrypted
      render json: { error: 'PDF encrypted' }, status: :unprocessable_entity
    end
  end
end
