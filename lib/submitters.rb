# frozen_string_literal: true

module Submitters
  module_function

  def select_attachments_for_download(submitter)
    original_documents = submitter.submission.template.documents.preload(:blob)
    is_more_than_two_images = original_documents.count(&:image?) > 1

    submitter.documents.preload(:blob).reject do |attachment|
      is_more_than_two_images && original_documents.find { |a| a.uuid == attachment.uuid }&.image?
    end
  end
end
