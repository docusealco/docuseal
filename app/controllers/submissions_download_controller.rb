# frozen_string_literal: true

class SubmissionsDownloadController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    submitter = Submitter.find_by(slug: params[:submitter_slug])

    Submissions::GenerateResultAttachments.call(submitter)

    redirect_to submitter.archive.url, allow_other_host: true
  end
end
