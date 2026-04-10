# frozen_string_literal: true

class SubmissionsPreviewDownloadController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  TTL = 40.minutes

  def index
    @submission = Submission.find_by!(slug: params[:submission_slug] || params[:submissions_preview_slug])

    last_submitter = @submission.submitters.where.not(completed_at: nil).order(:completed_at).last

    return head :not_found unless last_submitter

    Submissions::EnsureResultGenerated.call(last_submitter)

    unless current_user_submission?(@submission)
      if use_2fa?(@submission)
        Rollbar.info("2FA download error: #{last_submitter.id}") if defined?(Rollbar)

        return head :not_found
      end

      if last_submitter.completed_at < TTL.ago
        Rollbar.info("TTL: #{last_submitter.id}") if defined?(Rollbar)

        return head :not_found
      end
    end

    if params[:combined] == 'true'
      respond_with_combined(last_submitter)
    else
      render json: Submitters.build_document_urls(last_submitter)
    end
  end

  private

  def respond_with_combined(submitter)
    url = Submitters.build_combined_url(submitter)

    if url
      render json: [url]
    else
      head :not_found
    end
  end

  def current_user_submission?(submission)
    current_user && current_ability.can?(:read, submission)
  end

  def use_2fa?(submission)
    return true if submission.submitters.any? do |e|
      e.preferences['require_phone_2fa'] || e.preferences['require_email_2fa']
    end
    return true if submission.template&.preferences&.dig('require_phone_2fa')
    return true if submission.template&.preferences&.dig('require_email_2fa')

    false
  end
end
