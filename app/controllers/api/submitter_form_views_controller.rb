# frozen_string_literal: true

module Api
  class SubmitterFormViewsController < ApiBaseController
    skip_before_action :authenticate_user!
    skip_authorization_check

    def create
      submitter = Submitter.find_by!(slug: params[:submitter_slug])

      submitter.opened_at = Time.current
      submitter.save

      SubmissionEvents.create_with_tracking_data(submitter, 'view_form', request)

      SendFormViewedWebhookRequestJob.perform_async({ 'submitter_id' => submitter.id })

      render json: {}
    end
  end
end
