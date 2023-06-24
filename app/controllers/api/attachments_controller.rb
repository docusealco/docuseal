# frozen_string_literal: true

module Api
  class AttachmentsController < ApiBaseController
    skip_before_action :authenticate_user!

    def create
      submitter = Submitter.find_by!(slug: params[:submitter_slug])

      blob = ActiveStorage::Blob.find_signed(params[:blob_signed_id])

      attachment = ActiveStorage::Attachment.create!(
        blob:,
        name: params[:name],
        record: submitter
      )

      render json: attachment.as_json(only: %i[uuid], methods: %i[url filename content_type])
    end
  end
end
