# frozen_string_literal: true

class ExportSubmissionService < ExportService
  attr_reader :submission

  def initialize(submission)
    super()
    @submission = submission
  end

  def call
    unless export_location&.submissions_endpoint.present?
      set_error('Export failed: Submission export endpoint is not configured.')
      return false
    end

    payload = build_payload
    response = post_to_api(payload, export_location.submissions_endpoint, export_location.extra_params)

    if response&.success?
      true
    else
      set_error("Failed to export submission ##{submission.id} events.")
      false
    end
  rescue Faraday::Error => e
    Rails.logger.error("Failed to export submission Faraday: #{e.message}")
    Rollbar.error("Failed to export submission: #{e.message}") if defined?(Rollbar)
    set_error("Network error occurred during export: #{e.message}")
    false
  rescue StandardError => e
    Rails.logger.error("Failed to export submission: #{e.message}")
    Rollbar.error(e) if defined?(Rollbar)
    set_error("An unexpected error occurred during export: #{e.message}")
    false
  end

  private

  def build_payload
    {
      submission_id: submission.id,
      template_name: submission.template&.name,
      events: submission.submission_events.order(updated_at: :desc).limit(1)
    }
  end
end
