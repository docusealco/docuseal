# frozen_string_literal: true

class SubmissionsDownloadController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    submission = Submission.find_by(slug: params[:submission_slug])

    Submissions::GenerateResultAttachments.call(submission)

    redirect_to submission.archive.url, allow_other_host: true
  end
end
