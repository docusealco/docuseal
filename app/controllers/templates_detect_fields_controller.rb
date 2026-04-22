# frozen_string_literal: true

class TemplatesDetectFieldsController < ApplicationController
  include ActionController::Live

  load_and_authorize_resource :template

  def create
    if params[:algorithm].present?
      create_with_algorithm
    else
      create_with_ml_detection
    end
  end

  private

  def create_with_algorithm
    documents = @template.schema_documents.preload(:blob)

    fields = Templates::FieldDetection.call(@template, params[:algorithm], documents)

    render json: { fields: fields, submitters: @template.submitters, completed: true }
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def create_with_ml_detection
    response.headers['Content-Type'] = 'text/event-stream'

    sse = SSE.new(response.stream)

    documents = @template.schema_documents.preload(:blob)
    documents = documents.where(uuid: params[:attachment_uuid]) if params[:attachment_uuid].present?

    page_number = params[:page].presence&.to_i

    documents.each do |document|
      io = StringIO.new(document.download)

      Templates::DetectFields.call(io, attachment: document, page_number:) do |(attachment_uuid, page, fields)|
        sse.write({ attachment_uuid:, page:, fields: })
      end
    end

    sse.write({ completed: true })
  ensure
    response.stream.close
  end
end
