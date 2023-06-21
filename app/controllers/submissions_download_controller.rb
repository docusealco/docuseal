# frozen_string_literal: true

class SubmissionsDownloadController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    submitter = Submitter.find_by(slug: params[:submitter_slug])

    Submissions::GenerateResultAttachments.call(submitter) if submitter.documents.blank?

    original_documents = submitter.submission.template.documents.preload(:blob)
    is_more_than_two_images = original_documents.count(&:image?) > 1

    urls = submitter.documents.preload(:blob).filter_map do |attachment|
      next if is_more_than_two_images && original_documents.find { |a| a.uuid == attachment.uuid }&.image?

      helpers.rails_blob_url(attachment)
    end

    render json: urls
  end
end
