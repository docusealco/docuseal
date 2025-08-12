# frozen_string_literal: true

class TemplatesDebugController < ApplicationController
  load_and_authorize_resource :template

  DEBUG_FILE = ''

  def show
    attachment = @template.documents.first

    data = attachment.download
    pdf = HexaPDF::Document.new(io: StringIO.new(data))

    fields = Templates::FindAcroFields.call(pdf, attachment, data)

    attachment.metadata['pdf'] ||= {}
    attachment.metadata['pdf']['fields'] = fields

    @template.update!(fields: Templates::ProcessDocument.normalize_attachment_fields(@template, [attachment]))

    debug_file if DEBUG_FILE.present?

    ActiveRecord::Associations::Preloader.new(
      records: [@template],
      associations: [schema_documents: { preview_images_attachments: :blob }]
    ).call

    @template_data =
      @template.as_json.merge(
        documents: @template.schema_documents.as_json(
          methods: %i[metadata signed_uuid],
          include: { preview_images: { methods: %i[url metadata filename] } }
        )
      ).to_json

    render 'templates/edit', layout: 'plain'
  end

  def debug_file
    tempfile = Tempfile.new
    tempfile.binmode
    tempfile.write(File.read(DEBUG_FILE))
    tempfile.rewind

    filename = File.basename(DEBUG_FILE)

    file = ActionDispatch::Http::UploadedFile.new(
      tempfile:,
      filename:,
      type: Marcel::MimeType.for(tempfile)
    )

    params = { files: [file] }

    documents = Templates::CreateAttachments.call(@template, params)

    schema = documents.map { |doc| { attachment_uuid: doc.uuid, name: doc.filename.base } }

    @template.update!(schema:)
  end
end
