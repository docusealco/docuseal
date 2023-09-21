# frozen_string_literal: true

class TemplatesUploadsController < ApplicationController
  load_and_authorize_resource :template, parent: false

  def create
    @template.account = current_account
    @template.author = current_user
    @template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:folder_name])
    @template.name = File.basename(params[:files].first.original_filename, '.*')

    @template.save!

    documents = Templates::CreateAttachments.call(@template, params)

    schema = documents.map { |doc| { attachment_uuid: doc.uuid, name: doc.filename.base } }

    @template.update!(schema:)

    redirect_to edit_template_path(@template)
  end
end
