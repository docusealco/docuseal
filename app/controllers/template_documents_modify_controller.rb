# frozen_string_literal: true

class TemplateDocumentsModifyController < ApplicationController
  load_and_authorize_resource :template

  def create
    authorize!(:update, @template)

    documents_layout =
      params.require(:documents).map do |item|
        item.permit(:attachment_uuid,
                    pages: [:attachment_uuid, :page, :rotate,
                            { redact: [%i[x y w h color]], replaced_page: %i[attachment_uuid page] }]).to_h
      end

    Templates::ModifyDocuments.call(@template, documents_layout)

    render json: {
      schema: @template.schema,
      fields: @template.fields,
      submitters: @template.submitters,
      documents: @template.schema_documents.reload.preload(:blob, preview_images_attachments: :blob).as_json(
        methods: %i[metadata signed_key],
        include: {
          preview_images: { methods: %i[url metadata filename] }
        }
      )
    }
  rescue Templates::ModifyDocuments::InvalidLayout
    render json: { error: I18n.t(:unable_to_save) }, status: :unprocessable_content
  end
end
