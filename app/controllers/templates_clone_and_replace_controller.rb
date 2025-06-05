# frozen_string_literal: true

class TemplatesCloneAndReplaceController < ApplicationController
  load_and_authorize_resource :template

  def create
    return head :unprocessable_entity if params[:files].blank?

    ActiveRecord::Associations::Preloader.new(
      records: [@template],
      associations: [schema_documents: :preview_images_attachments]
    ).call

    cloned_template = Templates::Clone.call(@template, author: current_user)
    cloned_template.name = File.basename(params[:files].first.original_filename, '.*')
    cloned_template.save!

    documents = Templates::ReplaceAttachments.call(cloned_template, params, extract_fields: true)

    cloned_template.save!

    Templates::CloneAttachments.call(template: cloned_template, original_template: @template,
                                     excluded_attachment_uuids: documents.map(&:uuid))

    SearchEntries.enqueue_reindex(cloned_template)

    respond_to do |f|
      f.html { redirect_to edit_template_path(cloned_template) }
      f.json { render json: { id: cloned_template.id } }
    end
  rescue Templates::CreateAttachments::PdfEncrypted
    respond_to do |f|
      f.html { render turbo_stream: turbo_stream.append(params[:form_id], html: helpers.tag.prompt_password) }
      f.json { render json: { error: 'PDF encrypted', status: 'pdf_encrypted' }, status: :unprocessable_entity }
    end
  end
end
