# frozen_string_literal: true

class TemplateDocumentsController < ApplicationController
  load_and_authorize_resource :template

  def create
    if params[:blobs].blank? && params[:files].blank?
      return render json: { error: 'File is missing' }, status: :unprocessable_entity
    end

    old_fields_hash = @template.fields.hash

    documents = Templates::CreateAttachments.call(@template, params, extract_fields: true)

    schema = documents.map do |doc|
      { attachment_uuid: doc.uuid, name: doc.filename.base }
    end

    render json: {
      schema:,
      fields: old_fields_hash == @template.fields.hash ? nil : @template.fields,
      submitters: old_fields_hash == @template.fields.hash ? nil : @template.submitters,
      documents: documents.as_json(
        methods: %i[metadata signed_uuid],
        include: {
          preview_images: { methods: %i[url metadata filename] }
        }
      )
    }
  rescue Templates::CreateAttachments::PdfEncrypted
    render json: { error: 'PDF encrypted' }, status: :unprocessable_entity
  end
end
