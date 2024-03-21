# frozen_string_literal: true

class SubmissionsDownloadController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  TTL = 40.minutes
  FILES_TTL = 5.minutes

  def index
    submitter = Submitter.find_signed(params[:sig], purpose: :download_completed) if params[:sig].present?

    signature_valid =
      if submitter&.slug == params[:submitter_slug]
        true
      else
        submitter = nil
      end

    submitter ||= Submitter.find_by!(slug: params[:submitter_slug])

    Submissions::EnsureResultGenerated.call(submitter)

    last_submitter = submitter.submission.submitters.where.not(completed_at: nil).order(:completed_at).last

    Submissions::EnsureResultGenerated.call(last_submitter)

    return head :not_found unless last_submitter.completed_at?

    if last_submitter.completed_at < TTL.ago && !signature_valid && !current_user_submitter?(last_submitter)
      Rollbar.info("TTL: #{last_submitter.id}") if defined?(Rollbar)

      return head :not_found
    end

    render json: build_urls(last_submitter)
  end

  private

  def current_user_submitter?(submitter)
    current_user && current_user.account.submitters.exists?(id: submitter.id)
  end

  def build_urls(submitter)
    Submitters.select_attachments_for_download(submitter).map do |attachment|
      ActiveStorage::Blob.proxy_url(attachment.blob, expires_at: FILES_TTL.minutes.from_now.to_i)
    end
  end
end
