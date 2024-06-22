# frozen_string_literal: true

class TemplatesDebugController < ApplicationController
  load_and_authorize_resource :template

  def show
    attachment = @template.documents.first

    pdf = HexaPDF::Document.new(io: StringIO.new(attachment.download))

    fields = Templates::FindAcroFields.call(pdf, attachment)

    attachment.metadata['pdf'] ||= {}
    attachment.metadata['pdf']['fields'] = fields

    @template.update!(fields: Templates::ProcessDocument.normalize_attachment_fields(@template, [attachment]))

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
end
