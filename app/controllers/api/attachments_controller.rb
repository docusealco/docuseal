# frozen_string_literal: true

module Api
  class AttachmentsController < ApiBaseController
    skip_before_action :authenticate_user!

    def create
      submitter = Submitter.find_by!(slug: params[:submitter_slug])

      blob =
        if (file = params[:file])
          ActiveStorage::Blob.create_and_upload!(io: file.open,
                                                 filename: file.original_filename,
                                                 content_type: file.content_type)
        else
          ActiveStorage::Blob.find_signed(params[:blob_signed_id])
        end

      attachment = ActiveStorage::Attachment.create!(
        blob:,
        name: params[:name],
        record: submitter
      )

      render json: attachment.as_json(only: %i[uuid], methods: %i[url filename content_type])
    end
  end
end
