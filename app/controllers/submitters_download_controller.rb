# frozen_string_literal: true

class SubmittersDownloadController < ApplicationController
  load_and_authorize_resource :submitter

  def index
    Submissions::EnsureResultGenerated.call(@submitter)

    render json: Submitters.build_document_urls(@submitter)
  end
end
