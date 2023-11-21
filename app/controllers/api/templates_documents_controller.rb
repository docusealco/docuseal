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
      document = template.documents.find(params[:documentId])
      img_attachment_id = params[:attachment_id]
      page_number = document.preview_images.find_index { |pic| pic.id == img_attachment_id }
      if page_number
        Templates::ProcessDocument.delete_picture(template, document, img_attachment_id, page_number)
        render json: { success: true, message: 'image deleted successfully' }
      else
        page_number = "No image found for deletion"
        render json: { success: false, message: "Error: #{page_number}" }, status: :unprocessable_entity
      end
    end
    
    def add_new_image
      template = Template.find(params[:template_id])
      raw_document = params[:document]
      document = template.documents.find_by(id: raw_document[:id])
      begin
        Templates::ProcessDocument.upload_new_blank_image(template, document)
        render json: { success: true, message: 'New blank image added successfully' }
      rescue StandardError => e
        render json: { success: false, message: "Error adding new blank image: #{e.message}" }, status: :unprocessable_entity
      end
    end

  end
end
