# frozen_string_literal: true

class UploadToPaperlessJob
  include Sidekiq::Job

  sidekiq_options queue: :integrations

  MAX_ATTEMPTS = 10

  def perform(params = {})
    return unless Submissions::UploadToPaperless.configured?

    submission = Submission.find_by(id: params['submission_id'])

    return unless submission

    attempt = params['attempt'].to_i

    Submissions::UploadToPaperless.call(submission)
  rescue Submissions::UploadToPaperless::UploadError, Faraday::Error => e
    return if attempt >= MAX_ATTEMPTS

    Rails.logger.warn("Paperless-ngx upload failed (attempt #{attempt}): #{e.message}")

    UploadToPaperlessJob.perform_in(
      (2**attempt).minutes,
      'submission_id' => params['submission_id'],
      'attempt' => attempt + 1
    )
  end
end
