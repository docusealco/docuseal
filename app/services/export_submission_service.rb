# frozen_string_literal: true

class ExportSubmissionService < ExportService
  attr_reader :submission

  def initialize(submission)
    super()
    @submission = submission
  end

  def call
    export_location = ExportLocation.default_location

    if export_location&.submissions_endpoint.blank?
      record_error('Export failed: Submission export endpoint is not configured.')
      return false
    end

    payload = build_payload
    response = post_to_api(payload, export_location.submissions_endpoint, export_location.extra_params)

    if response&.success?
      true
    else
      record_error("Failed to export submission ##{submission.id} events.")
      false
    end
  rescue Faraday::Error => e
    Rails.logger.error("Failed to export submission Faraday: #{e.message}")
    Rollbar.error("Failed to export submission: #{e.message}") if defined?(Rollbar)
    record_error("Network error occurred during export: #{e.message}")
    false
  rescue StandardError => e
    Rails.logger.error("Failed to export submission: #{e.message}")
    Rollbar.error(e) if defined?(Rollbar)
    record_error("An unexpected error occurred during export: #{e.message}")
    false
  end

  private

  def build_payload
    {
      external_submission_id: submission.id,
      template_name: submission.template&.name,
      status: submission_status,
      submitter_data: submission.submitters.map do |submitter|
        {
          external_submitter_id: submitter.slug,
          name: submitter.name,
          email: submitter.email,
          status: submitter.status,
          completed_at: submitter.completed_at,
          declined_at: submitter.declined_at
        }
      end,
      created_at: submission.created_at,
      updated_at: submission.updated_at
    }
  end

  def submission_status
    # The status is tracked for each submitter, so we need to check the status of all submitters
    statuses = submission.submitters.map(&:status)

    if statuses.include?('declined')
      'declined'
    elsif statuses.all?('completed')
      'completed'
    elsif statuses.include?('changes_requested')
      'changes_requested'
    elsif statuses.any?('opened')
      'in_progress'
    elsif statuses.any?('sent')
      'sent'
    else
      'pending'
    end
  end
end
