# frozen_string_literal: true

module Api
  class AttachmentsController < ApiBaseController
    skip_before_action :authenticate_user!
    skip_authorization_check

    def create
      record = if params[:template_slug].present?
        Template.find_by!(slug: params[:template_slug])
      else
        Submitter.find_by!(slug: params[:submitter_slug])
      end
      attachment = Submitters.create_attachment!(record, params)

      render json: attachment.as_json(only: %i[uuid], methods: %i[url filename content_type])
    end
  end
end
