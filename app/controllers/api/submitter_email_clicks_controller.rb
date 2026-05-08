# frozen_string_literal: true

module Api
  class SubmitterEmailClicksController < ApiBaseController
    skip_before_action :authenticate_user!
    skip_authorization_check

    def create
      @submitter = Submitter.find_by!(slug: params[:submitter_slug])
      @embed_cors_account = @submitter.account

      set_embed_cors_headers

      if params[:t] == SubmissionEvents.build_tracking_param(@submitter, 'click_email')
        SubmissionEvents.create_with_tracking_data(@submitter, 'click_email', request)
      end

      render json: {}
    end
  end
end
