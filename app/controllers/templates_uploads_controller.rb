# frozen_string_literal: true

class TemplatesUploadsController < ApplicationController
  load_and_authorize_resource :template, parent: false

  layout 'plain'

  def show; end

  def create
    url_params = create_file_params_from_url if params[:url].present?

    save_template!(@template, url_params)

    documents = Templates::CreateAttachments.call(@template, url_params || params, extract_fields: true)
    schema = documents.map { |doc| { attachment_uuid: doc.uuid, name: doc.filename.base } }

    if @template.fields.blank?
      @template.fields = Templates::ProcessDocument.normalize_attachment_fields(@template, documents)

      schema.each { |item| item['pending_fields'] = true } if @template.fields.present?
    end

    @template.update!(schema:)

    SendTemplateCreatedWebhookRequestJob.perform_async('template_id' => @template.id)

    redirect_to edit_template_path(@template)
  rescue Templates::CreateAttachments::PdfEncrypted
    render turbo_stream: turbo_stream.append(params[:form_id], html: helpers.tag.prompt_password)
  rescue StandardError => e
    Rollbar.error(e) if defined?(Rollbar)

    raise if Rails.env.local?

    redirect_to root_path, alert: 'Unable to upload file'
  end

  private

  def save_template!(template, url_params)
    template.account = current_account
    template.author = current_user
    template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:folder_name])
    template.name = File.basename((url_params || params)[:files].first.original_filename, '.*')

    template.save!

    template
  end

  def create_file_params_from_url
    tempfile = Tempfile.new
    tempfile.binmode
    tempfile.write(conn.get(Addressable::URI.parse(params[:url]).display_uri.to_s).body)
    tempfile.rewind

    file = ActionDispatch::Http::UploadedFile.new(
      tempfile:,
      filename: File.basename(
        URI.decode_www_form_component(params[:filename].presence || params[:url]), '.*'
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
