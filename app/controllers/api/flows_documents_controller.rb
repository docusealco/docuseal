# frozen_string_literal: true

module Api
  class FlowsDocumentsController < ApiBaseController
    def create
      @flow = current_account.flows.find(params[:flow_id])

      documents =
        params[:blobs].map do |blob|
          blob = ActiveStorage::Blob.find_signed(blob[:signed_id])

          document = @flow.documents.create!(blob:)

          Flows::ProcessDocument.call(document)
        end

      schema = documents.map do |doc|
        { attachment_uuid: doc.uuid, name: doc.filename.base }
      end

      render json: {
        schema:,
        documents: documents.as_json(
          include: {
            preview_images: { methods: %i[url metadata filename] }
          }
        )
      }
    end
  end
end
