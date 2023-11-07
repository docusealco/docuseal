# frozen_string_literal: true

class TemplatesUploadsController < ApplicationController
  load_and_authorize_resource :template, parent: false

  layout 'plain'

  def show; end

  def create
    url_params = create_file_params_from_url if params[:url].present?

    @template.account = current_account
    @template.author = current_user
    @template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:folder_name])
    @template.name = File.basename((url_params || params)[:files].first.original_filename, '.*')

    @template.save!

    documents = Templates::CreateAttachments.call(@template, url_params || params)

    schema = documents.map { |doc| { attachment_uuid: doc.uuid, name: doc.filename.base } }

    @template.update!(schema:)

    redirect_to edit_template_path(@template)
  rescue StandardError => e
    Rollbar.error(e) if defined?(Rollbar)

    redirect_to root_path, alert: 'Unable to upload file'
  end

  private

  def create_file_params_from_url
    tempfile = Tempfile.new
    tempfile.binmode
    tempfile.write(conn.get(params[:url]).body)
    tempfile.rewind

    file = ActionDispatch::Http::UploadedFile.new(
      tempfile:,
      filename: File.basename(
        URI.decode_www_form_component(params[:filename].presence || params[:url])
      ),
      type: Marcel::MimeType.for(tempfile)
    )

    { files: [file] }
  end

  def conn
    Faraday.new do |faraday|
      faraday.response :follow_redirects
    end
  end
end
