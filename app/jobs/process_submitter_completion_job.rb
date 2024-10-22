# frozen_string_literal: true

class ProcessSubmitterCompletionJob
  include Sidekiq::Job

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])

    create_completed_submitter!(submitter)

    is_all_completed = !submitter.submission.submitters.exists?(completed_at: nil)

    if !is_all_completed && submitter.submission.submitters_order_preserved?
      enqueue_next_submitter_request_notification(submitter)
    end

    Submissions::EnsureResultGenerated.call(submitter)

    if is_all_completed && submitter.completed_at == submitter.submission.submitters.maximum(:completed_at)
      if submitter.submission.account.account_configs.exists?(key: AccountConfig::COMBINE_PDF_RESULT_KEY, value: true)
        Submissions::GenerateCombinedAttachment.call(submitter)
      end

      Submissions::GenerateAuditTrail.call(submitter.submission)

      enqueue_completed_emails(submitter)
    end

    create_completed_documents!(submitter)

    enqueue_completed_webhooks(submitter, is_all_completed:)
  end

  def create_completed_submitter!(submitter)
    submission = submitter.submission
    sms_count = submitter.submission_events.where(event_type: %w[send_sms send_2fa_sms]).count
    completed_submitter = CompletedSubmitter.where(submitter_id: submitter.id).first_or_initialize
    completed_submitter.assign_attributes(
      submission_id: submitter.submission_id,
      account_id: submission.account_id,
      template_id: submission.template_id,
      source: submission.source,
      sms_count:,
      completed_at: submitter.completed_at
    )

    completed_submitter.save!
  end

  def create_completed_documents!(submitter)
    submitter.documents.map { |s| s.metadata['sha256'] }.compact_blank.each do |sha256|
      CompletedDocument.where(submitter_id: submitter.id, sha256:).first_or_create!
    end
  end

  def enqueue_completed_webhooks(submitter, is_all_completed: false)
    webhook_config = Accounts.load_webhook_config(submitter.account)

    if webhook_config
      SendFormCompletedWebhookRequestJob.perform_async({ 'submitter_id' => submitter.id,
                                                         'encrypted_config_id' => webhook_config.id })
    end

    webhook_urls = submitter.account.webhook_urls

    webhook_urls = webhook_urls.where(
      Arel::Table.new(:webhook_urls)[:events].matches('%"form.completed"%')
    ).or(
      webhook_urls.where(
        Arel::Table.new(:webhook_urls)[:events].matches('%"submission.completed"%')
      )
    )

    webhook_urls.each do |webhook|
      if webhook.events.include?('form.completed')
        SendFormCompletedWebhookRequestJob.perform_async({ 'submitter_id' => submitter.id,
                                                           'webhook_url_id' => webhook.id })
      end

      if webhook.events.include?('submission.completed') && is_all_completed
        SendSubmissionCompletedWebhookRequestJob.perform_async({ 'submission_id' => submitter.submission_id,
                                                                 'webhook_url_id' => webhook.id })
      end
    end
  end

  def enqueue_completed_emails(submitter)
    submission = submitter.submission

    user = submission.created_by_user || submitter.template.author

    if submitter.account.users.exists?(id: user.id) && submission.preferences['send_email'] != false &&
       submitter.template.preferences['completed_notification_email_enabled'] != false
      if submission.submitters.map(&:email).exclude?(user.email) &&
         user.user_configs.find_by(key: UserConfig::RECEIVE_COMPLETED_EMAIL)&.value != false &&
         user.role != 'integration'
        SubmitterMailer.completed_email(submitter, user).deliver_later!
      end

      build_bcc_addresses(submission).each do |to|
        SubmitterMailer.completed_email(submitter, user, to:).deliver_later!
      end
    end

    to = build_to_addresses(submitter)

    return if to.blank? || submitter.template.preferences['documents_copy_email_enabled'] == false

    SubmitterMailer.documents_copy_email(submitter, to:).deliver_later!
  end

  def build_bcc_addresses(submission)
    bcc = submission.preferences['bcc_completed'].presence ||
          submission.template.preferences['bcc_completed'].presence ||
          submission.account.account_configs
                    .find_by(key: AccountConfig::BCC_EMAILS)&.value

    bcc.to_s.scan(User::EMAIL_REGEXP)
  end

  def build_to_addresses(submitter)
    submitter.submission.submitters.reject { |e| e.preferences['send_email'] == false }
             .sort_by(&:completed_at).select(&:email?).map(&:friendly_name).join(', ')
  end

  def enqueue_next_submitter_request_notification(submitter)
    next_submitter_item =
      submitter.submission.template_submitters.find do |e|
        sub = submitter.submission.submitters.find { |s| s.uuid == e['uuid'] }

        sub.completed_at.blank? && sub.sent_at.blank?
      end

    return unless next_submitter_item

    next_submitter = submitter.submission.submitters.find { |s| s.uuid == next_submitter_item['uuid'] }

    Submitters.send_signature_requests([next_submitter])
  end
end
