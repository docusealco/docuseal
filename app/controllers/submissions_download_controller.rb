# frozen_string_literal: true

class SubmissionsDownloadController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    submitter = Submitter.find_by(slug: params[:submitter_slug])

    Submissions::GenerateResultAttachments.call(submitter) if submitter.documents.blank?

    render json: submitter.documents.map { |e| helpers.rails_blob_url(e) }
  end
end
