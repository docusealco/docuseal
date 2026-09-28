# frozen_string_literal: true

module Api
  class SubmitterFormViewsController < ActionController::API
    def create
      @submitter = Submitter.find_by!(slug: params[:submitter_slug])

      @submitter.opened_at = Time.current
      @submitter.save

      SubmissionEvents.create_with_tracking_data(@submitter, 'view_form', request)

      WebhookUrls.enqueue_events(@submitter, 'form.viewed')

      render json: {}
    end
  end
end
