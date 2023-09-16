# frozen_string_literal: true

module Api
  class SubmitterEmailClicksController < ApiBaseController
    skip_before_action :authenticate_user!
    skip_authorization_check

    def create
      submitter = Submitter.find_by!(slug: params[:submitter_slug])

      if params[:t] == SubmissionEvents.build_tracking_param(submitter, 'click_email')
        SubmissionEvents.create_with_tracking_data(submitter, 'click_email', request)
      end

      render json: {}
    end
  end
end
