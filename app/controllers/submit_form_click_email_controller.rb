# frozen_string_literal: true

class SubmitFormClickEmailController < ActionController::API
  def create
    @submitter = Submitter.find_by!(slug: params[:submit_form_slug])

    if params[:t].present? && params[:t] == SubmissionEvents.build_tracking_param(@submitter, 'click_email')
      SubmissionEvents.create_with_tracking_data(@submitter, 'click_email', request)
    end

    render json: {}
  end
end
