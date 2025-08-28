# frozen_string_literal: true

require 'faraday'

class ExportController < ApplicationController
  skip_authorization_check
  skip_before_action :verify_authenticity_token

  # Send template to third party.
  def export_template
    data = request.raw_post.present? ? JSON.parse(request.raw_post) : params.to_unsafe_h
    service = ExportTemplateService.new(data)

    if service.call
      head :ok
    else
      redirect_to root_path, alert: service.error_message
    end
  end

  # Send submission to third party.
  def export_submission
    submission = Submission.find(params[:id])
    service = ExportSubmissionService.new(submission)

    if service.call
      redirect_to submission, notice: "Submission ##{submission.id} events exported successfully."
    else
      redirect_to submission, alert: service.error_message
    end
  end
end
