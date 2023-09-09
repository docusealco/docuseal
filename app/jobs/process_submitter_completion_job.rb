# frozen_string_literal: true

class ProcessSubmitterCompletionJob < ApplicationJob
  def perform(submitter)
    is_all_completed = !submitter.submission.submitters.exists?(completed_at: nil)

    Submissions::EnsureResultGenerated.call(submitter)

    if submitter.account.encrypted_configs.exists?(key: EncryptedConfig::WEBHOOK_URL_KEY)
      SendWebhookRequestJob.perform_later(submitter)
    end

    return unless is_all_completed
    return if submitter.completed_at != submitter.submission.submitters.maximum(:completed_at)

    enqueue_emails(submitter)
  end

  def enqueue_emails(submitter)
    user = submitter.submission.created_by_user || submitter.template.author

    if submitter.template.account.users.exists?(id: user.id)
      bcc = submitter.submission.template.account.account_configs.find_by(key: 'bcc_emails')&.value

      SubmitterMailer.completed_email(submitter, user, bcc:).deliver_later!
    end

    to = submitter.submission.submitters.order(:completed_at).select(&:email?).map(&:friendly_name).join(', ')

    SubmitterMailer.documents_copy_email(submitter, to:).deliver_later! if to.present?
  end
end
