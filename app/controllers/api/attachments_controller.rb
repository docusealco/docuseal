# frozen_string_literal: true

module Api
  class AttachmentsController < ApiBaseController
    skip_before_action :authenticate_user!

    def create
      submitter = Submitter.find_by!(slug: params[:submitter_slug])

      attachment = Submitters.create_attachment!(submitter, params)

      render json: attachment.as_json(only: %i[uuid], methods: %i[url filename content_type])
    end
  end
end
