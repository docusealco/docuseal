# frozen_string_literal: true

class GenerateVoidedDocumentsJob
  include Sidekiq::Job

  sidekiq_options queue: :default

  def perform(params = {})
    submission = Submission.find_by(id: params['submission_id'])

    return unless submission&.voided_at?

    Submissions::GenerateVoidedDocuments.call(submission)
  end
end
