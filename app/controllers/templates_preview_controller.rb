# frozen_string_literal: true

class TemplatesPreviewController < ApplicationController
  load_and_authorize_resource :template

  def show
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

    render :show, layout: 'plain'
  end
end
