# frozen_string_literal: true

module Api
  class SubmitterFormViewsController < ApiBaseController
    skip_before_action :authenticate_user!

    def create
      submitter = Submitter.find_by!(slug: params[:submitter_slug])

      SubmissionEvents.create_with_tracking_data(submitter, 'view_form', request)

      render json: {}
    end
  end
end
