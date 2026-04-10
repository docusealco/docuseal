# frozen_string_literal: true

class SubmissionsDownloadController < ApplicationController
  load_and_authorize_resource :submission

  def index
    last_submitter = @submission.submitters.where.not(completed_at: nil).order(:completed_at).last

    return head :not_found unless last_submitter

    Submissions::EnsureResultGenerated.call(last_submitter)

    if params[:combined] == 'true'
      url = Submitters.build_combined_url(last_submitter)

      if url
        render json: [url]
      else
        head :not_found
      end
    else
      render json: Submitters.build_document_urls(last_submitter)
    end
  end
end
