# frozen_string_literal: true

class SubmissionsDownloadController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def index
    submitter = Submitter.find_by(slug: params[:submitter_slug])

    Submissions::EnsureResultGenerated.call(submitter)

    last_submitter = submitter.submission.submitters.where.not(completed_at: nil).order(:completed_at).last

    Submissions::EnsureResultGenerated.call(last_submitter)

    urls =
      Submitters.select_attachments_for_download(last_submitter).map do |attachment|
        ActiveStorage::Blob.proxy_url(attachment.blob)
      end

    render json: urls
  end
end
