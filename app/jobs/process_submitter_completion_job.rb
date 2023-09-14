# frozen_string_literal: true

class ProcessSubmitterCompletionJob < ApplicationJob
  def perform(submitter)
    is_all_completed = !submitter.submission.submitters.exists?(completed_at: nil)

    if !is_all_completed && submitter.submission.submitters_order_preserved?
      enqueue_next_submitter_request_notification(submitter)
    end

    Submissions::EnsureResultGenerated.call(submitter)

    if submitter.account.encrypted_configs.exists?(key: EncryptedConfig::WEBHOOK_URL_KEY)
      SendFormCompletedWebhookRequestJob.perform_later(submitter)
    end

    return unless is_all_completed
    return if submitter.completed_at != submitter.submission.submitters.maximum(:completed_at)

    Submissions::GenerateAuditTrail.call(submitter.submission)

    enqueue_emails(submitter)
  end

  def enqueue_emails(submitter)
    user = submitter.submission.created_by_user || submitter.template.author

    if submitter.template.account.users.exists?(id: user.id)
      bcc = submitter.submission.template.account.account_configs.find_by(key: 'bcc_emails')&.value

      SubmitterMailer.completed_email(submitter, user, bcc:).deliver_later!
    end

    to = submitter.submission.submitters.sort_by(&:completed_at).select(&:email?).map(&:friendly_name).join(', ')

    SubmitterMailer.documents_copy_email(submitter, to:).deliver_later! if to.present?
  end

  def enqueue_next_submitter_request_notification(submitter)
    next_submitter_item =
      submitter.submission.template_submitters.find do |e|
        sub = submitter.submission.submitters.find { |s| s.uuid == e['uuid'] }

        sub.completed_at.blank? && sub.sent_at.blank?
      end

    return unless next_submitter_item

    next_submitter = submitter.submission.submitters.find { |s| s.uuid == next_submitter_item['uuid'] }

    Submitters.send_signature_requests([next_submitter], send_email: true)
  end
end
