# frozen_string_literal: true

class TemplateDocumentsPageObjectsController < ApplicationController
  load_and_authorize_resource :template

  def index
    attachment = @template.documents_attachments.find_by!(uuid: params[:attachment_uuid])

    render json: Templates::ModifyDocuments.page_objects(attachment, params[:page].to_i)
  end
end
