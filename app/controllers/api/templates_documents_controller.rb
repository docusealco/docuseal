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
    end

    def del_image
      template = Template.find(params[:template_id])
      attachment_id = params[:attachment_id]
      document_id = params[:documentId]
      page_number = template.documents.find(document_id).preview_images.find_index { |pic| pic.id == attachment_id }
      if page_number
        Templates::ProcessDocument.delete_picture(template, attachment_id, page_number)
        render json: { success: true, message: 'New blank image added successfully' }
      else
        page_number = "No image found for deletion"
        render json: { success: false, message: "Error: #{page_number}" }, status: :unprocessable_entity
      end
    end
    
    def add_new_image
      byebug
      template = Template.find(params[:template_id])
      begin
        Templates::ProcessDocument.upload_new_blank_image(template)
        render json: { success: true, message: 'New blank image added successfully' }
      rescue StandardError => e
        render json: { success: false, message: "Error adding new blank image: #{e.message}" }, status: :unprocessable_entity
      end
    end

  end
end
