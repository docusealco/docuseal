# frozen_string_literal: true

class SubmissionsDownloadController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    submitter = Submitter.find_by(slug: params[:submitter_slug])

    Submissions::EnsureResultGenerated.call(submitter)

    urls =
      Submitters.select_attachments_for_download(submitter).map do |attachment|
        helpers.rails_blob_url(attachment)
      end

    render json: urls
  end
end
