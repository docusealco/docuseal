# frozen_string_literal: true

module Api
  class TemplatesDocumentsController < ApiBaseController
    def create
      return head :unprocessable_entity if params[:blobs].blank? && params[:files].blank?

      @template = current_account.templates.find(params[:template_id])

      documents = Templates::CreateAttachments.call(@template, params)

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
  end
end
