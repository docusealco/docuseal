# frozen_string_literal: true

class TemplateDocumentsCropController < ApplicationController
  load_and_authorize_resource :template
  before_action :load_attachment

  rescue_from Leptonica::LeptonicaError do
    render json: { error: I18n.t(:unable_to_save) }, status: :unprocessable_content
  end

  def index
    render json: { corners: Leptonica.detect_document_corners(@attachment.download) }
  end

  def create
    authorize!(:update, @template)

    document = Templates::CreateDocumentCrop.call(@template, @attachment, crop_params)

    render json: {
      document: document.as_json(
        methods: %i[metadata signed_key],
        include: {
          preview_images: { methods: %i[url metadata filename] }
        }
      )
    }
  end

  private

  def load_attachment
    @attachment = @template.documents_attachments.find_by!(uuid: params[:attachment_uuid])
  end

  def crop_params
    params.permit(:scan, :rotate, :flip_h, :flip_v, corners: [%i[x y]])
  end
end
